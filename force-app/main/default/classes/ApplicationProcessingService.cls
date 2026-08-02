/**
 * @description Core business logic for incoming applications, shared by the LWC controller
 *              (ApplicationFormController) and the REST webhook (ApplicationWebhookService).
 *              Validates the payload, checks for duplicates and decides whether the application
 *              becomes an Opportunity (existing Account) or a Lead (new or existing Lead).
 * @author      Guilherme Ferreira
 * @date        08/02/2026
 */
public virtual with sharing class ApplicationProcessingService {

    /**
     * @description Thrown when the application payload cannot be processed at all.
     */
    public class ApplicationProcessingServiceException extends Exception {}
    @TestVisible
    private static SObjectDuplicateMatcher matcher = new SObjectDuplicateMatcher();

    private static final String EMAIL_PATTERN =
        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

    /**
     * @description Processes an application end to end: validates the input, searches for duplicate
     *              records and routes the application accordingly. When a matching Account exists an
     *              Opportunity is created; otherwise a Lead is inserted, or updated when a matching
     *              Lead is found.
     * @param       input Application data submitted by the LWC form or by the webhook.
     * @return      ApplicationResult describing the created/updated record or the validation errors.
     * @throws      ApplicationProcessingServiceException When the input is null.
     */
    virtual
    public ApplicationResult processApplication(ApplicationDTO input) {
        System.debug('processApplication: ' + JSON.serialize(input));
        List<String> errors = validate(input);

        if (!errors.isEmpty()) {
            return new ApplicationResult(String.join(errors, ';'));
        }

        Lead lead = buildLead(input);
        Map<String, List<Id>> duplicates = matcher.findDuplicateRecords(lead);
        System.debug('duplicates: ' + JSON.serialize(duplicates));

        if (duplicates.containsKey('Account') && !duplicates.get('Account').isEmpty()) {
            return createOpportunity(input, duplicates.get('Account')[0]);
        }

        Id leadId = null;
        if (duplicates.containsKey('Lead') && !duplicates.get('Lead').isEmpty()) {
            leadId = duplicates.get('Lead')[0];
        }

        lead.Id = leadId;
        return createLead(lead);

    }

    /**
     * @description Validates the required application fields (company, federal tax id, annual revenue
     *              and contact data), including the e-mail format.
     * @param       input Application data to be validated.
     * @return      List of validation messages; empty when the application is valid.
     * @throws      ApplicationProcessingServiceException When the input is null.
     */
    @TestVisible
    virtual
    private List<String> validate(ApplicationDTO input) {
        List<String> errors = new List<String>();

        if (input == null) {
            throw new ApplicationProcessingServiceException('Application data is required.');
        }

        if (String.isBlank(input.companyName)) {
            errors.add('Company Name is required.');
        }
        if (String.isBlank(input.federalTaxId)) {
            errors.add('Federal Tax Id is required.');
        }
        if (input.annualRevenue == null || input.annualRevenue <= 0) {
            errors.add('Annual Revenue must be greater than 0.');
        }

        if (input.contact == null) {
            errors.add('Contact information is required.');
        } else {
            if (String.isBlank(input.contact.firstName)) {
                errors.add('First Name is required.');
            }
            if (String.isBlank(input.contact.lastName)) {
                errors.add('Last Name is required.');
            }
            if (String.isBlank(input.contact.email)) {
                errors.add('Email is required.');
            } else if (!Pattern.compile(EMAIL_PATTERN).matcher(input.contact.email.trim()).matches()) {
                errors.add('Email format is invalid.');
            }
            if (String.isBlank(input.contact.phone)) {
                errors.add('Phone is required.');
            }
        }

        return errors;
    }

    /**
     * @description Creates an Opportunity and a Contact under an existing Account. Both DML
     *              operations are partial-success so their errors can be collected and returned
     *              together to the caller.
     * @param       input     Application data used to build the records.
     * @param       accountId Id of the Account matched by the duplicate rules.
     * @return      ApplicationResult with the new Opportunity id, or the concatenated DML errors on failure.
     */
    @TestVisible
    virtual
    private ApplicationResult createOpportunity(ApplicationDTO input, Id accountId) {
        Opportunity opp = buildOpportunity(input, accountId);
        Contact contact = buildContact(input, accountId);

        Database.SaveResult sr = Database.insert(opp, false);
        Database.SaveResult srContact = Database.insert(contact, false);

        if (!sr.isSuccess() || !srContact.isSuccess()) {
            List<String> messages = new List<String>();
            for (Database.Error err : sr.getErrors()) {
                messages.add(err.getMessage());
            }
            for (Database.Error err : srContact.getErrors()) {
                messages.add(err.getMessage());
            }
            return new ApplicationResult(String.join(messages, ';'));
        }

        return new ApplicationResult('Opportunity', opp.Id);
    }

    /**
     * @description Upserts the Lead, inserting a new record when the Id is null or updating the
     *              existing Lead matched by the duplicate rules.
     * @param       lead Lead built from the application data, with or without an Id.
     * @return      ApplicationResult with the Lead id, or the concatenated DML errors on failure.
     */
    @TestVisible
    virtual
    private ApplicationResult createLead(Lead lead) {
        Database.UpsertResult sr = Database.upsert(lead, false);

        if (!sr.isSuccess()) {
            List<String> messages = new List<String>();
            for (Database.Error err : sr.getErrors()) {
                messages.add(err.getMessage());
            }
            return new ApplicationResult(String.join(messages, ';'));
        }

        return new ApplicationResult('Lead', lead.Id);
    }

    /**
     * @description Builds an in-memory Lead from the application data. The record is also used as
     *              the input of the duplicate check before being saved.
     * @param       input Application data submitted by the caller.
     * @return      Unsaved Lead with the status defaulted to 'Open - Not Contacted'.
     */
    @TestVisible
    virtual
    private Lead buildLead(ApplicationDTO input) {
        return new Lead(
            FirstName = input.contact.firstName,
            LastName = input.contact.lastName,
            Company = input.companyName,
            Email = input.contact.email,
            Phone = input.contact.phone,
            AnnualRevenue = input.annualRevenue,
            Federal_Tax_Id__c = input.federalTaxId,
            Application_Source__c = input.applicationSource,
            Status = 'Open - Not Contacted'
        );
    }

    /**
     * @description Builds an in-memory Opportunity for an existing Account, defaulting the stage to
     *              'Prospecting' and the close date to 30 days from today.
     * @param       input     Application data submitted by the caller.
     * @param       accountId Id of the Account the Opportunity belongs to.
     * @return      Unsaved Opportunity ready to be inserted.
     */
    @TestVisible
    virtual
    private Opportunity buildOpportunity(ApplicationDTO input, Id accountId) {
        return new Opportunity(
            Name = input.companyName.trim() + ' - New Application',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Application_Source__c = input.applicationSource
        );
    }

    /**
     * @description Builds an in-memory Contact from the application contact data, related to the
     *              existing Account.
     * @param       input     Application data submitted by the caller.
     * @param       accountId Id of the Account the Contact belongs to.
     * @return      Unsaved Contact ready to be inserted.
     */
    @TestVisible
    virtual
    private Contact buildContact(ApplicationDTO input, Id accountId) {
        return new Contact(
            FirstName = input.contact.firstName,
            LastName = input.contact.lastName,
            Email = input.contact.email,
            Phone = input.contact.phone,
            AccountId = accountId
        );
    }

}