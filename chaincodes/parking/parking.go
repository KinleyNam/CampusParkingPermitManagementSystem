package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Permit represents a campus parking permit
type Permit struct {
	PermitID      string `json:"permitId"`
	StudentID     string `json:"studentId"`
	VehicleNumber string `json:"vehicleNumber"`
	PermitType    string `json:"permitType"`
	IssuedBy      string `json:"issuedBy"`
	IssueDate     string `json:"issueDate"`
	ExpiryDate    string `json:"expiryDate"`
	Status        string `json:"status"`
	ParkingZone   string `json:"parkingZone"`
}

// Violation represents a parking violation recorded by security
type Violation struct {
	ViolationID   string `json:"violationId"`
	PermitID      string `json:"permitId"`
	StudentID     string `json:"studentId"`
	VehicleNumber string `json:"vehicleNumber"`
	Description   string `json:"description"`
	RecordedBy    string `json:"recordedBy"`
	Timestamp     string `json:"timestamp"`
	Fine          string `json:"fine"`
}

// StudentEligibility represents a student's eligibility for a parking permit
type StudentEligibility struct {
	StudentID  string `json:"studentId"`
	Name       string `json:"name"`
	IsEligible bool   `json:"isEligible"`
	Program    string `json:"program"`
	ApprovedBy string `json:"approvedBy"`
	UpdatedAt  string `json:"updatedAt"`
}

// ParkingContract is the smart contract for parking-main-channel operations
type ParkingContract struct {
	contractapi.Contract
}

// ==================== PERMIT FUNCTIONS ====================

// IssuePermit creates a new parking permit. Only UniversityAdminMSP may call this.
func (p *ParkingContract) IssuePermit(ctx contractapi.TransactionContextInterface,
	permitId, studentId, vehicleNumber, permitType, issueDate, expiryDate, parkingZone string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "UniversityAdminMSP" {
		return fmt.Errorf("access denied: only UniversityAdmin can issue permits (caller: %s)", mspID)
	}

	existing, err := ctx.GetStub().GetState(permitId)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("permit %s already exists", permitId)
	}

	permit := Permit{
		PermitID:      permitId,
		StudentID:     studentId,
		VehicleNumber: vehicleNumber,
		PermitType:    permitType,
		IssuedBy:      mspID,
		IssueDate:     issueDate,
		ExpiryDate:    expiryDate,
		Status:        "Active",
		ParkingZone:   parkingZone,
	}

	permitJSON, err := json.Marshal(permit)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(permitId, permitJSON); err != nil {
		return fmt.Errorf("failed to save permit: %v", err)
	}

	return ctx.GetStub().SetEvent("PermitIssued",
		[]byte(fmt.Sprintf("Issued permit %s for student %s", permitId, studentId)))
}

// ReadPermit retrieves a parking permit by ID. Any channel member may query.
func (p *ParkingContract) ReadPermit(ctx contractapi.TransactionContextInterface, permitId string) (*Permit, error) {
	permitJSON, err := ctx.GetStub().GetState(permitId)
	if err != nil {
		return nil, fmt.Errorf("failed to read world state: %v", err)
	}
	if permitJSON == nil {
		return nil, fmt.Errorf("permit %s does not exist", permitId)
	}

	var permit Permit
	if err = json.Unmarshal(permitJSON, &permit); err != nil {
		return nil, err
	}
	return &permit, nil
}

// UpdatePermitStatus updates the status of an existing permit. Only UniversityAdminMSP may call this.
func (p *ParkingContract) UpdatePermitStatus(ctx contractapi.TransactionContextInterface,
	permitId, newStatus string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "UniversityAdminMSP" {
		return fmt.Errorf("access denied: only UniversityAdmin can update permit status (caller: %s)", mspID)
	}

	permit, err := p.ReadPermit(ctx, permitId)
	if err != nil {
		return err
	}

	permit.Status = newStatus
	permitJSON, err := json.Marshal(permit)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(permitId, permitJSON); err != nil {
		return fmt.Errorf("failed to update permit: %v", err)
	}

	return ctx.GetStub().SetEvent("PermitStatusUpdated",
		[]byte(fmt.Sprintf("Permit %s status changed to %s", permitId, newStatus)))
}

// RevokePermit sets a permit's status to Revoked. Only UniversityAdminMSP may call this.
func (p *ParkingContract) RevokePermit(ctx contractapi.TransactionContextInterface, permitId string) error {
	return p.UpdatePermitStatus(ctx, permitId, "Revoked")
}

// VerifyPermit checks whether a permit is currently Active. Any channel member may call this.
func (p *ParkingContract) VerifyPermit(ctx contractapi.TransactionContextInterface, permitId string) (bool, error) {
	permit, err := p.ReadPermit(ctx, permitId)
	if err != nil {
		return false, err
	}
	isValid := permit.Status == "Active"
	_ = ctx.GetStub().SetEvent("PermitVerified",
		[]byte(fmt.Sprintf("Permit %s verified: valid=%v", permitId, isValid)))
	return isValid, nil
}

// ==================== VIOLATION FUNCTIONS ====================

// RecordViolation records a parking violation. Only SecurityMSP may call this.
func (p *ParkingContract) RecordViolation(ctx contractapi.TransactionContextInterface,
	violationId, permitId, studentId, vehicleNumber, description, timestamp, fine string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "SecurityMSP" {
		return fmt.Errorf("access denied: only Security can record violations (caller: %s)", mspID)
	}

	existing, err := ctx.GetStub().GetState(violationId)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("violation %s already exists", violationId)
	}

	violation := Violation{
		ViolationID:   violationId,
		PermitID:      permitId,
		StudentID:     studentId,
		VehicleNumber: vehicleNumber,
		Description:   description,
		RecordedBy:    mspID,
		Timestamp:     timestamp,
		Fine:          fine,
	}

	violationJSON, err := json.Marshal(violation)
	if err != nil {
		return err
	}
	if err = ctx.GetStub().PutState(violationId, violationJSON); err != nil {
		return fmt.Errorf("failed to save violation: %v", err)
	}

	return ctx.GetStub().SetEvent("ViolationRecorded",
		[]byte(fmt.Sprintf("Recorded violation %s for student %s", violationId, studentId)))
}

// ReadViolation retrieves a violation by ID. Any channel member may query.
func (p *ParkingContract) ReadViolation(ctx contractapi.TransactionContextInterface, violationId string) (*Violation, error) {
	violationJSON, err := ctx.GetStub().GetState(violationId)
	if err != nil {
		return nil, fmt.Errorf("failed to read world state: %v", err)
	}
	if violationJSON == nil {
		return nil, fmt.Errorf("violation %s does not exist", violationId)
	}

	var violation Violation
	if err = json.Unmarshal(violationJSON, &violation); err != nil {
		return nil, err
	}
	return &violation, nil
}

// DeleteViolation removes a violation record. Only SecurityMSP may call this.
func (p *ParkingContract) DeleteViolation(ctx contractapi.TransactionContextInterface, violationId string) error {
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "SecurityMSP" {
		return fmt.Errorf("access denied: only Security can delete violations (caller: %s)", mspID)
	}

	existing, err := ctx.GetStub().GetState(violationId)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if existing == nil {
		return fmt.Errorf("violation %s does not exist", violationId)
	}

	if err = ctx.GetStub().DelState(violationId); err != nil {
		return fmt.Errorf("failed to delete violation: %v", err)
	}

	return ctx.GetStub().SetEvent("ViolationDeleted",
		[]byte(fmt.Sprintf("Deleted violation %s", violationId)))
}

// ==================== STUDENT ELIGIBILITY FUNCTIONS ====================

// SetStudentEligibility creates or updates a student's eligibility record. Only StudentAffairsMSP may call this.
func (p *ParkingContract) SetStudentEligibility(ctx contractapi.TransactionContextInterface,
	studentId, name string, isEligible bool, program, updatedAt string) error {

	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}
	if mspID != "StudentAffairsMSP" {
		return fmt.Errorf("access denied: only StudentAffairs can set eligibility (caller: %s)", mspID)
	}

	eligibility := StudentEligibility{
		StudentID:  studentId,
		Name:       name,
		IsEligible: isEligible,
		Program:    program,
		ApprovedBy: mspID,
		UpdatedAt:  updatedAt,
	}

	eligibilityJSON, err := json.Marshal(eligibility)
	if err != nil {
		return err
	}

	key := "ELIGIBILITY_" + studentId
	if err = ctx.GetStub().PutState(key, eligibilityJSON); err != nil {
		return fmt.Errorf("failed to save eligibility: %v", err)
	}

	return ctx.GetStub().SetEvent("EligibilityUpdated",
		[]byte(fmt.Sprintf("Updated eligibility for student %s: eligible=%v", studentId, isEligible)))
}

// GetStudentEligibility retrieves a student's eligibility record. Any channel member may query.
func (p *ParkingContract) GetStudentEligibility(ctx contractapi.TransactionContextInterface, studentId string) (*StudentEligibility, error) {
	key := "ELIGIBILITY_" + studentId
	eligibilityJSON, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read world state: %v", err)
	}
	if eligibilityJSON == nil {
		return nil, fmt.Errorf("eligibility record for student %s does not exist", studentId)
	}

	var eligibility StudentEligibility
	if err = json.Unmarshal(eligibilityJSON, &eligibility); err != nil {
		return nil, err
	}
	return &eligibility, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(ParkingContract))
	if err != nil {
		fmt.Printf("Error creating parking chaincode: %s\n", err.Error())
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting parking chaincode: %s\n", err.Error())
	}
}
