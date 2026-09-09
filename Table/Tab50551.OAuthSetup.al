table 50551 "OAuth Setup"
{
    DataClassification = CustomerContent;
    Caption = 'OAuth Setup';

    fields
    {
        // ฟิลด์ Primary Key บังคับมี 1 บรรทัด
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Client ID"; Text[250])
        {
            Caption = 'Client ID';
        }
        field(3; "Client Secret"; Text[250])
        {
            Caption = 'Client Secret';
        }
        field(4; "Target Endpoint URL"; Text[250])
        {
            Caption = 'Target Endpoint URL';
        }
        field(5; "Token Endpoint URL"; Text[250])
        {
            Caption = 'Token Endpoint URL';
        }
        field(6; "Scope"; Text[250])
        {
            Caption = 'Scope';
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