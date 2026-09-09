table 50549 "COOP_LogAPI_Por"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; CreateLog; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(3; UpdateLog; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(4; SuccessLog; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(5; ApiType; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Document No."; Text[250])
        {
            DataClassification = ToBeClassified;
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
