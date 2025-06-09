import { LightningElement, api, track } from 'lwc';

export default class ApplicationProcessOfferPresentation extends LightningElement {
    @api applicationId;
    @api totalLoanAmountRequested;
    @api interestRate;
    @api monthlyPayment;
    @api termMonths;
}
