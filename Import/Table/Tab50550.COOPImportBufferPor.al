table 50550 "COOP_Import_Buffer_Por"
{
    DataClassification = CustomerContent;
    Caption = 'COOP Sales Import Buffer';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(4; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(5; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
        }
        field(6; "Status"; Option)
        {
            Caption = 'Status';
            OptionMembers = Draft,Pending,Processing,Processed,Error,Skipped;
            OptionCaption = 'Draft,Pending,Processing,Processed,Error,Skipped';
        }
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(8; "Raw Payload"; Blob)
        {
            Caption = 'Raw Payload';
        }
        field(9; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(11; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
        }
        field(13; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
        field(14; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}