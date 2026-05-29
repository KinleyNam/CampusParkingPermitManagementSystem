package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Payment represents a parking fee payment on the finance channel
type Payment struct {
	PaymentID   string `json:"paymentId"`
	StudentID   string `json:"studentId"`
	PermitID    string `json:"permitId"`
	Amount      string `json:"amount"`
	PaymentDate string `json:"paymentDate"`
	Status      string `json:"status"`
	ConfirmedBy string `json:"confirmedBy"`
}

// FinanceContract is the smart contract for finance-channel operations
type FinanceContract struct {
	contractapi.Contract
}

// RecordPayment creates a pending payment record. Only UniversityAdminMSP may call this.
func (f *FinanceContract) RecordPayment(ctx contractapi.TransactionContextInterface,
	paymentId, studentId, permitId, amount, paymentDate string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "UniversityAdminMSP" {
		return fmt.Errorf("access denied: only UniversityAdmin can record payments (caller: %s)", mspID)
	}

	existing, err := ctx.GetStub().GetState(paymentId)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("payment %s already exists", paymentId)
	}

	payment := Payment{
		PaymentID:   paymentId,
		StudentID:   studentId,
		PermitID:    permitId,
		Amount:      amount,
		PaymentDate: paymentDate,
		Status:      "Pending",
		ConfirmedBy: "",
	}

	paymentJSON, err := json.Marshal(payment)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(paymentId, paymentJSON); err != nil {
		return fmt.Errorf("failed to save payment: %v", err)
	}

	return ctx.GetStub().SetEvent("PaymentRecorded",
		[]byte(fmt.Sprintf("Recorded payment %s for student %s", paymentId, studentId)))
}

// ReadPayment retrieves a payment by ID. Any channel member may query.
func (f *FinanceContract) ReadPayment(ctx contractapi.TransactionContextInterface, paymentId string) (*Payment, error) {
	paymentJSON, err := ctx.GetStub().GetState(paymentId)
	if err != nil {
		return nil, fmt.Errorf("failed to read world state: %v", err)
	}
	if paymentJSON == nil {
		return nil, fmt.Errorf("payment %s does not exist", paymentId)
	}

	var payment Payment
	if err = json.Unmarshal(paymentJSON, &payment); err != nil {
		return nil, err
	}
	return &payment, nil
}

// ConfirmPayment marks a payment as Confirmed. Only FinanceMSP may call this.
func (f *FinanceContract) ConfirmPayment(ctx contractapi.TransactionContextInterface, paymentId string) error {
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "FinanceMSP" {
		return fmt.Errorf("access denied: only Finance can confirm payments (caller: %s)", mspID)
	}

	payment, err := f.ReadPayment(ctx, paymentId)
	if err != nil {
		return err
	}
	if payment.Status == "Confirmed" {
		return fmt.Errorf("payment %s is already confirmed", paymentId)
	}

	payment.Status = "Confirmed"
	payment.ConfirmedBy = mspID

	paymentJSON, err := json.Marshal(payment)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(paymentId, paymentJSON); err != nil {
		return fmt.Errorf("failed to confirm payment: %v", err)
	}

	return ctx.GetStub().SetEvent("PaymentConfirmed",
		[]byte(fmt.Sprintf("Confirmed payment %s", paymentId)))
}

// UpdatePayment updates payment details. Only UniversityAdminMSP may call this.
func (f *FinanceContract) UpdatePayment(ctx contractapi.TransactionContextInterface,
	paymentId, amount, paymentDate string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "UniversityAdminMSP" {
		return fmt.Errorf("access denied: only UniversityAdmin can update payments (caller: %s)", mspID)
	}

	payment, err := f.ReadPayment(ctx, paymentId)
	if err != nil {
		return err
	}
	if payment.Status == "Confirmed" {
		return fmt.Errorf("cannot update a confirmed payment")
	}

	payment.Amount = amount
	payment.PaymentDate = paymentDate

	paymentJSON, err := json.Marshal(payment)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(paymentId, paymentJSON); err != nil {
		return fmt.Errorf("failed to update payment: %v", err)
	}

	return ctx.GetStub().SetEvent("PaymentUpdated",
		[]byte(fmt.Sprintf("Updated payment %s", paymentId)))
}

// DeletePayment removes a pending payment record. Only UniversityAdminMSP may call this.
func (f *FinanceContract) DeletePayment(ctx contractapi.TransactionContextInterface, paymentId string) error {
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "UniversityAdminMSP" {
		return fmt.Errorf("access denied: only UniversityAdmin can delete payments (caller: %s)", mspID)
	}

	payment, err := f.ReadPayment(ctx, paymentId)
	if err != nil {
		return err
	}
	if payment.Status == "Confirmed" {
		return fmt.Errorf("cannot delete a confirmed payment")
	}

	if err = ctx.GetStub().DelState(paymentId); err != nil {
		return fmt.Errorf("failed to delete payment: %v", err)
	}

	return ctx.GetStub().SetEvent("PaymentDeleted",
		[]byte(fmt.Sprintf("Deleted payment %s", paymentId)))
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(FinanceContract))
	if err != nil {
		fmt.Printf("Error creating finance chaincode: %s\n", err.Error())
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting finance chaincode: %s\n", err.Error())
	}
}
