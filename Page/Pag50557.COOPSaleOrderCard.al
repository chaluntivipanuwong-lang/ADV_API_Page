page 50557 "COOP Sale Order Card"
{
    PageType = Document;
    Caption = 'COOP Sales Order';
    SourceTable = COOP_Sale_Header_Por;
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field(County; Rec.County)
                {
                    ApplicationArea = All;
                }
                field(Country; Rec.Country)
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = false; // ให้ระบบคำนวณจาก Subform เท่านั้น
                }
            }

            part(Lines; "COOP Sale Order Subform")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Document No." = field("Document No.");
                UpdatePropagation = Both; // ทำให้การเปลี่ยนแปลงใน ListPart ส่งผลให้หน้า Header รีเฟรชทันที
            }
        }
    }
}