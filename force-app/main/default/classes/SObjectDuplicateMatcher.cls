/**
 * @description Wrapper around the Datacloud.FindDuplicates API used to detect existing records
 *              that match an in-memory SObject, according to the active matching and duplicate rules.
 *              Runs `without sharing` so that duplicates owned by other users are also detected.
 * @author      Guilherme Ferreira
 * @date        08/02/2026
 */
public virtual without sharing class SObjectDuplicateMatcher {
    
    /**
     * @description Runs the active duplicate rules for the given record and groups the matched
     *              record ids by SObject API name (e.g. 'Lead', 'Account').
     * @param       input Unsaved SObject to be evaluated against the duplicate rules.
     * @return      Map of SObject API name to the list of matching record ids; empty map when the input is null or no duplicate is found.
     */
    virtual
    public Map<String, List<Id>> findDuplicateRecords(SObject input) {
        
        if (input == null) {
            return new Map<String, List<Id>>();
        }

        List<Datacloud.FindDuplicatesResult> findResults = Datacloud.FindDuplicates.findDuplicates(new List<SObject>{ input });

        Map<String, List<Id>> duplicates = new Map<String, List<Id>>();

        for (Datacloud.FindDuplicatesResult fdr : findResults) {
            System.debug('fdr: ' + JSON.serialize(fdr));
            for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                System.debug('dr: ' + JSON.serialize(dr));
                for (Datacloud.MatchResult mr : dr.getMatchResults()) {
                    System.debug('mr: ' + JSON.serialize(mr));
                    for (Datacloud.MatchRecord rec : mr.getMatchRecords()) {
                        System.debug('rec: ' + JSON.serialize(rec));
                        SObject matched = rec.getRecord();
                        if (matched != null && matched.Id != null) {
                            if (!duplicates.containsKey(matched.getSObjectType().getDescribe().getName())) {
                                duplicates.put(matched.getSObjectType().getDescribe().getName(), new List<Id>());
                            }
                            duplicates.get(matched.getSObjectType().getDescribe().getName()).add(matched.Id);
                        }
                    }
                }
            }
        }

        return duplicates;
    }

}