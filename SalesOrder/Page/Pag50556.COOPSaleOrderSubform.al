page 50556 "COOP Sale Order Subform"
{
    PageType = ListPart;
    Caption = 'Lines';
    SourceTable = COOP_Sale_Line_Por;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateLineAndHeader();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateLineAndHeader();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateLineAndHeader();
                    end;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        // เมื่อลบแถว ให้คำนวณและส่งยอดรวมใหม่ขึ้น Header
        UpdateHeaderTotal(true);
    end;

    local procedure UpdateLineAndHeader()
    begin
        Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
        Rec.Modify();
        UpdateHeaderTotal(false);
        CurrPage.Update(true); // สั่งรีเฟรชหน้าจอ Subform และส่งสัญญาณขึ้นไปที่หน้าแม่
    end;

    local procedure UpdateHeaderTotal(IsDeleting: Boolean)
    var
        SalesHeader: Record COOP_Sale_Header_Por;
        SalesLine: Record COOP_Sale_Line_Por;
        SumAmount: Decimal;
    begin
        SalesLine.SetRange("Document No.", Rec."Document No.");
        if SalesLine.FindSet() then
            repeat
                if not (IsDeleting and (SalesLine."Line No." = Rec."Line No.")) then
                    SumAmount += SalesLine."Line Amount";
            until SalesLine.Next() = 0;

        if SalesHeader.Get(Rec."Document No.") then begin
            SalesHeader."Total Amount" := SumAmount;
            SalesHeader.Modify(true);
        end;
    end;
}