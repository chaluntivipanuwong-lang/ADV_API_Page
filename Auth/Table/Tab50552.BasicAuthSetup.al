table 50552 BasicAuthSetup
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Endpoint URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3; Username; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Password; Text[250])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

}