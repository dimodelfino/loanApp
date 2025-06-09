@isTest
public class GetLoanOfferTest {

    @isTest
    static void testGetLoanOffer_SuccessPath() {
        GetLoanOffer.ApplicationInput input = new GetLoanOffer.ApplicationInput();
        input.firstName = 'Test';
        input.lastName = 'User';
        input.email = 'test.user@example.com';
        input.phone = '1234567890';
        input.BorrowerSSN = '123456789';
        input.street = '123 Main St';
        input.city = 'Metropolis';
        input.state = 'NY';
        input.postalCode = '10001';
        input.totalLoanAmountRequested = 10000;
        input.numberOfActiveCreditCards = 3;

        List<GetLoanOffer.ApplicationInput> inputs = new List<GetLoanOffer.ApplicationInput>{ input };

        Test.startTest();
        List<GetLoanOffer.ApplicationOutput> outputs = GetLoanOffer.getLoanOfferFromOfferService(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected one result');
        GetLoanOffer.ApplicationOutput result = outputs[0];

        System.assert(result.isSuccess, 'Expected result to be successful');
        System.assertNotEquals(null, result.account, 'Expected Account to be present');
        System.assertNotEquals(null, result.account.Id, 'Expected Account to be inserted');
        System.assertNotEquals(null, result.application, 'Expected Application__c to be present');
        System.assertNotEquals(null, result.application.Id, 'Expected Application__c to be inserted');
        System.assertEquals(10000, result.totalLoanAmountRequested, 'Loan amount mismatch');
        System.assertEquals(3, result.numberOfActiveCreditCards, 'Credit card count mismatch');
        System.assert(result.monthlyPayment > 0, 'Expected monthly payment to be calculated');
    }

    @isTest
    static void testGetLoanOffer_AmountValidationFails() {
        GetLoanOffer.ApplicationInput input = new GetLoanOffer.ApplicationInput();
        input.firstName = 'test';
        input.lastName = 'user';
        input.email = 'mail@test.com';
        input.BorrowerSSN = '556486545';
        input.totalLoanAmountRequested = 5000;
        input.numberOfActiveCreditCards = -1;

        List<GetLoanOffer.ApplicationInput> inputs = new List<GetLoanOffer.ApplicationInput>{ input };

        Test.startTest();
        List<GetLoanOffer.ApplicationOutput> outputs = GetLoanOffer.getLoanOfferFromOfferService(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected one result even on validation fail');
        GetLoanOffer.ApplicationOutput result = outputs[0];
        System.assertEquals(false, result.isSuccess, 'Expected validation to fail');
        System.assertEquals('Loan amount requested must be between $10,000 and $50,000.', result.errorMessage, 'Expected: Loan amount requested must be between $10,000 and $50,000.');
    }

    @isTest
    static void testGetLoanOffer_ActiveCreditCardsValidationFails() {
        GetLoanOffer.ApplicationInput input = new GetLoanOffer.ApplicationInput();
        input.firstName = 'test';
        input.lastName = 'user';
        input.email = 'mail@test.com';
        input.BorrowerSSN = '556486545';
        input.totalLoanAmountRequested = 15000;
        input.numberOfActiveCreditCards = 51;

        List<GetLoanOffer.ApplicationInput> inputs = new List<GetLoanOffer.ApplicationInput>{ input };

        Test.startTest();
        List<GetLoanOffer.ApplicationOutput> outputs = GetLoanOffer.getLoanOfferFromOfferService(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected one result even on validation fail');
        GetLoanOffer.ApplicationOutput result = outputs[0];
        System.assertEquals(false, result.isSuccess, 'Expected validation to fail');
        System.assertEquals('Number of active credit lines cannot exceed 50.', result.errorMessage, 'Expected: Number of active credit lines cannot exceed 50.');
    }

    @isTest
    static void testGetLoanOffer_NameValidationFails() {
        GetLoanOffer.ApplicationInput input = new GetLoanOffer.ApplicationInput();
        input.firstName = '';
        input.lastName = '';
        input.email = '';
        input.BorrowerSSN = '55648';
        input.totalLoanAmountRequested = 5000;
        input.numberOfActiveCreditCards = -1;

        List<GetLoanOffer.ApplicationInput> inputs = new List<GetLoanOffer.ApplicationInput>{ input };

        Test.startTest();
        List<GetLoanOffer.ApplicationOutput> outputs = GetLoanOffer.getLoanOfferFromOfferService(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected one result even on validation fail');
        GetLoanOffer.ApplicationOutput result = outputs[0];
        System.assertEquals(false, result.isSuccess, 'Expected validation to fail');
        System.assertEquals('Please complete both first and last name fields.', result.errorMessage, 'Expected: Please provide a valid email address.');
    }

    @isTest
    static void testGetLoanOffer_EmailValidationFails() {
        GetLoanOffer.ApplicationInput input = new GetLoanOffer.ApplicationInput();
        input.firstName = 'User';
        input.lastName = 'Test';
        input.email = '';
        input.BorrowerSSN = '55648';
        input.totalLoanAmountRequested = 5000;
        input.numberOfActiveCreditCards = -1;

        List<GetLoanOffer.ApplicationInput> inputs = new List<GetLoanOffer.ApplicationInput>{ input };

        Test.startTest();
        List<GetLoanOffer.ApplicationOutput> outputs = GetLoanOffer.getLoanOfferFromOfferService(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected one result even on validation fail');
        GetLoanOffer.ApplicationOutput result = outputs[0];
        System.assertEquals(false, result.isSuccess, 'Expected validation to fail');
        System.assertEquals('Please provide a valid email address.', result.errorMessage, 'Expected: Please provide a valid email address.');
    }
}
