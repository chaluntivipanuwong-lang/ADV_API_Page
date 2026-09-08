page 50553 "COOP_Post_Sale_Line_Por"
{
    PageType = API;
    Caption = 'Get Sale API';
    APIPublisher = 'avision';
    APIGroup = 'avapi';
    APIVersion = 'v1.0';
    EntityName = 'postsalelineapi';
    EntitySetName = 'postsalelineapis';
    SourceTable = COOP_Sale_Line_Por;
    DelayedInsert = true;
    ODataKeyFields = "Document No.", "Line No.";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(documentNo; Rec."Document No.") { }
                field(lineNo; Rec."Line No.") { }
                field(itemNo; Rec."Item No.") { }
                field(description; Rec.Description) { }
                field(quantity; Rec.Quantity) { }
                field(unitPrice; Rec."Unit Price") { }
                field(lineAmount; Rec."Line Amount") { }
            }
        }
    }
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SalesLine: Record COOP_Sale_Line_Por;
    begin
        // ป้องกันกรณี JSON ไม่ได้ส่ง lineNo มา ให้รันทีละ 10000 อัตโนมัติ
        if Rec."Line No." = 0 then begin
            SalesLine.SetRange("Document No.", Rec."Document No.");
            if SalesLine.FindLast() then
                Rec."Line No." := SalesLine."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;

        // คำนวณยอดเงินบรรทัดหากไม่ได้ส่งมา
        if (Rec."Line Amount" = 0) and (Rec.Quantity <> 0) and (Rec."Unit Price" <> 0) then
            Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        // คำนวณยอดเงินแถวใหม่ทุกครั้งที่มีการแก้จำนวนหรือราคาผ่าน PATCH
        Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.Delete(true);
        exit(true);
    end;

}