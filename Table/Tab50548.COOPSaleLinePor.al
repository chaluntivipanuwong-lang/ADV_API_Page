table 50548 "COOP_Sale_Line_Por"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
            TableRelation = COOP_Sale_Header_Por."Document No.";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Item No.';
        }
        field(4; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(5; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
            end;
        }
        field(6; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
            end;
        }
        field(7; "Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Line Amount';
            Editable = false;
        }
    }

    keys
    {
        key(pk; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        UpdateHeaderTotal();
    end;

    trigger OnModify()
    begin
        UpdateHeaderTotal();
    end;

    trigger OnDelete()
    begin
        UpdateHeaderTotalOnDelete();
    end;

    local procedure UpdateHeaderTotal()
    var
        HeaderRec: Record COOP_Sale_Header_Por;
        LineRec: Record COOP_Sale_Line_Por;
        Total: Decimal;
    begin
        LineRec.SetRange("Document No.", Rec."Document No.");
        if LineRec.FindSet() then
            repeat
                if LineRec."Line No." = Rec."Line No." then
                    Total += Rec."Line Amount" // ใช้ยอดปัจจุบันที่กำลังแก้
                else
                    Total += LineRec."Line Amount";
            until LineRec.Next() = 0
        else
            Total := Rec."Line Amount";

        if HeaderRec.Get(Rec."Document No.") then begin
            HeaderRec."Total Amount" := Total;
            HeaderRec.Modify();
        end;
    end;

    local procedure UpdateHeaderTotalOnDelete()
    var
        HeaderRec: Record COOP_Sale_Header_Por;
        LineRec: Record COOP_Sale_Line_Por;
        Total: Decimal;
    begin
        // ถ้า Header ไม่มีอยู่แล้ว ไม่ต้องทำอะไร
        if not HeaderRec.Get(Rec."Document No.") then
            exit;

        LineRec.SetRange("Document No.", Rec."Document No.");
        LineRec.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if LineRec.FindSet() then
            repeat
                Total += LineRec."Line Amount";
            until LineRec.Next() = 0;

        HeaderRec."Total Amount" := Total;
        HeaderRec.Modify();
    end;
}