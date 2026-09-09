table 50547 "COOP_Sale_Header_Por"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Customer No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Customer Name"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Address; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(5; Country; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(6; City; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(7; County; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Post Code"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Total Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

    }

    keys
    {
        key(pk; "Document No.")
        {
            Clustered = true;
        }
    }


}