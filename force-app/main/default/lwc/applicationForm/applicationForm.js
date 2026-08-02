import { LightningElement, track } from 'lwc';
import submitApplication from '@salesforce/apex/ApplicationFormController.submitApplication';

const EMPTY_APPLICATION = {
    companyName: '',
    federalTaxId: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    annualRevenue: null
};

export default class ApplicationForm extends LightningElement {
    @track application = { ...EMPTY_APPLICATION };

    isSubmitting = false;
    showSuccess = false;
    errorMessage = '';
    resultMessage = '';
    resultRecordType = '';

    handleChange(event) {
        const { name, value } = event.target;
        // console.log('handleChange', name, value);
        this.application = {
            ...this.application,
            [name]: name === 'annualRevenue' ? (value === '' ? null : value) : value
        };
        // console.log('application', JSON.stringify(this.application));
    }

    handleSubmit() {
        if (this.isSubmitting) {
            return;
        }

        this.errorMessage = '';

        const inputs = [...this.template.querySelectorAll('lightning-input')];
        const isValid = inputs.reduce((valid, input) => input.reportValidity() && valid, true);
        if (!isValid) {
            return;
        }

        const annualRevenue = Number(this.application.annualRevenue);
        if (!annualRevenue || annualRevenue <= 0) {
            this.errorMessage = 'Annual Revenue must be greater than 0.';
            return;
        }

        var input = {
            companyName: this.application.companyName,
            federalTaxId: this.application.federalTaxId,
            annualRevenue: this.application.annualRevenue,
            applicationSource: 'Community',
            contact: {
                firstName: this.application.firstName,
                lastName: this.application.lastName,
                email: this.application.email,
                phone: this.application.phone
            }
        };

        this.isSubmitting = true;
        submitApplication({ inputJson: JSON.stringify(input) })
        .then(result => {
            // console.log('result', JSON.stringify(result));
            if (result && result.success) {
                this.showSuccess = true;
                this.resultMessage = result.message;
                this.resultRecordType = result.recordType || '';
                this.resultRecordId = result.recordId || '';
            } else {
                this.errorMessage =
                    (result && result.message) || 'Unable to submit the application. Please try again.';
            }
        })
        .catch(error => {
            // console.log('catch error', error);
            this.errorMessage =
                (error && error.body && error.body.message) ||
                (error && error.message) ||
                'Unable to submit the application. Please try again.';
        })
        .finally(() => {
            this.isSubmitting = false;
        });

    }

    handleReset() {
        this.application = { ...EMPTY_APPLICATION };
        this.showSuccess = false;
        this.errorMessage = '';
        this.resultMessage = '';
        this.resultRecordType = '';
        this.isSubmitting = false;
    }
}
