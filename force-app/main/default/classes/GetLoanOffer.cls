public with sharing class GetLoanOffer {

    public static final Decimal hardcodedInterestRate = 19.5;
    public static final Integer hardcodedTermMonths = 36;
    public class ApplicationInput {
        @InvocableVariable()
        public String firstName;

        @InvocableVariable()
        public String lastName;

        @InvocableVariable()
        public String street;

        @InvocableVariable()
        public String city;

        @InvocableVariable()
        public String state;

        @InvocableVariable()
        public String country;

        @InvocableVariable()
        public String postalCode;

        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable()
        public String phone;

        @InvocableVariable(required=true)
        public String BorrowerSSN;

        @InvocableVariable(required=true)
        public Decimal totalLoanAmountRequested;

        @InvocableVariable(required=true)
        public Integer numberOfActiveCreditCards;
    }

    public class ApplicationOutput {
        @InvocableVariable(label='Is Application Valid')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Application ID')
        public Id applicationId;

        @InvocableVariable(label='Application ID')
        public Application__c application;

        @InvocableVariable(label='Account ID')
        public Account account;

        @InvocableVariable(label='Account ID')
        public Id accountId;

        @InvocableVariable(label='Calculated Monthly Payment')
        public Decimal monthlyPayment;

        @InvocableVariable(label='Interest Rate (Annual)')
        public Decimal interestRate;

        @InvocableVariable(label='Term (Months)')
        public Integer termMonths;

        @InvocableVariable(label='Total Loan Amount Requested')
        public Decimal totalLoanAmountRequested;

        @InvocableVariable(label='Number of Active Credit Cards')
        public Integer numberOfActiveCreditCards;
    }

    @InvocableMethod(label='Get Loan Offer' description='Processes loan application inputs, validates them, and creates necessary records.' category='Application')
    public static List<ApplicationOutput> getLoanOfferFromOfferService(List<ApplicationInput> inputs) {

        List<ApplicationOutput> results = new List<ApplicationOutput>();
        List<Account> accountsToInsert = new List<Account>();
        List<Application__c> applicationsToInsert = new List<Application__c>();

        try {
            for (ApplicationInput input : inputs) {

                ApplicationOutput output = validateInput(input);

                if(output.isSuccess == false){
                    results.add(output);
                    continue;
                }

                Account Client = new Account(
                    FirstName = input.firstName,
                    LastName = input.lastName,
                    PersonEmail = input.email,
                    PersonMobilePhone = input.phone,
                    SSN__c = input.BorrowerSSN,
                    BillingStreet = String.isNotBlank(input.street) ? input.street : '',
                    BillingCity = String.isNotBlank(input.city) ? input.city : '',
                    BillingState = String.isNotBlank(input.state) ? input.state : '',
                    BillingPostalCode = String.isNotBlank(input.postalCode) ? input.postalCode : ''
                );

                accountsToInsert.add(Client);
                output.account = Client;

                Application__c newApplication = new Application__c(
                    Client__c = Client.Id,
                    Total_Loan_Amount_Requested__c = input.totalLoanAmountRequested,
                    Number_Of_Active_Tradelines__c = input.numberOfActiveCreditCards,
                    Interest_Rate__c = hardcodedInterestRate,
                    Term_Length__c = hardcodedTermMonths
                );
                output.application = newApplication;
                output.totalLoanAmountRequested = input.totalLoanAmountRequested;
                output.numberOfActiveCreditCards = input.numberOfActiveCreditCards;

                applicationsToInsert.add(newApplication);
                Double monthlyRate = (hardcodedInterestRate / 100) / 12;
                Decimal loanAmount = input.totalLoanAmountRequested;

                Decimal powerTerm = Math.pow((1 + monthlyRate), (Double)hardcodedTermMonths);
                if (powerTerm - 1 == 0) {
                    output.monthlyPayment = 0;
                } else {
                    output.monthlyPayment = (loanAmount * monthlyRate * powerTerm) / (powerTerm - 1);
                }
                output.monthlyPayment = output.monthlyPayment.setScale(2);
                newApplication.Total_Loan_Amount__c = output.monthlyPayment * hardcodedTermMonths;

                results.add(output);
            }

            if (!accountsToInsert.isEmpty()) {
                insert accountsToInsert;
            }

            for(ApplicationOutput res : results) {
                if (res.application.Client__c == null) {
                    res.application.Client__c = res.account.Id;
                }
            }

            if (!applicationsToInsert.isEmpty()) {
                insert applicationsToInsert;
            }

            for(ApplicationOutput res : results) {
                if (res.applicationId == null) {
                    res.applicationId = res.application.Id;
                }
            }

        } catch (Exception e) {
            System.debug('Error in getLoanOfferFromOfferService: ' + e.getMessage() + ' at line ' + e.getLineNumber());

            if (results.isEmpty()) {
                ApplicationOutput errorOutput = new ApplicationOutput();
                errorOutput.isSuccess = false;
                errorOutput.errorMessage = 'An unexpected error occurred and no applications could be processed. (' + e.getMessage() + ')';
                results.add(errorOutput);
            } else {
                for (ApplicationOutput res : results) {
                    if (res.isSuccess) {
                        res.isSuccess = false;
                        res.errorMessage = 'An unexpected error occurred during application processing. Please try again. (' + e.getMessage() + ')';
                    }
                }
            }
        }

        return results;
    }

    public static ApplicationOutput validateInput(ApplicationInput input) {
        ApplicationOutput output = new ApplicationOutput();
        output.isSuccess = true;
        output.interestRate = hardcodedInterestRate;
        output.termMonths = hardcodedTermMonths;

        if(String.isBlank(input.firstName) || String.isBlank(input.lastName)) {
            output.isSuccess = false;
            output.errorMessage = 'Please complete both first and last name fields.';
        } else if(String.isBlank(input.email) || !Pattern.matches('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$', input.email.trim())) {
            output.isSuccess = false;
            output.errorMessage = 'Please provide a valid email address.';
        }else if(String.isBlank(input.BorrowerSSN) || !Pattern.matches('(\\d{9})', input.BorrowerSSN.trim())) {
            output.isSuccess = false;
            output.errorMessage = 'You must provide a valid SSN in the format XXX-XX-XXXX or XXXXXXXXX.';
        }else if (input.totalLoanAmountRequested < 10000 || input.totalLoanAmountRequested > 50000) {
            output.isSuccess = false;
            output.errorMessage = 'Loan amount requested must be between $10,000 and $50,000.';
        }else if (input.numberOfActiveCreditCards != null && (input.numberOfActiveCreditCards > 50 || input.numberOfActiveCreditCards < 0)) {
            output.isSuccess = false;
            output.errorMessage = 'Number of active credit lines cannot exceed 50.';
        }

        return output;
    }

    @AuraEnabled(cacheable=false)
    public static ApplicationOutput processLoanApplicationForLWC(ApplicationInput input) {
        List<ApplicationInput> singleInputList = new List<ApplicationInput>{input};
        List<ApplicationOutput> results = getLoanOfferFromOfferService(singleInputList);

        if (!results.isEmpty()) {
            return results[0];
        } else {
            ApplicationOutput errorOutput = new ApplicationOutput();
            errorOutput.isSuccess = false;
            errorOutput.errorMessage = 'An unexpected error occurred during LWC application processing. No result returned.';
            System.debug('LWC Processing Error: getLoanOfferFromOfferService returned empty results list.');
            return errorOutput;
        }
    }
}
