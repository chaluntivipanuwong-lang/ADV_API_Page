page 50565 "Temp Sale Order Subform"
{
    PageType = ListPart;
    Caption = 'Order Lines';
    SourceTable = COOP_Sale_Line_Por;
    SourceTableTemporary = true; // เก็บข้อมูลใน Memory ชั่วคราว
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        ItemRec: Record Item;
                    begin
                        if ItemRec.Get(Rec."Item No.") then begin
                            Rec.Description := ItemRec.Description;
                            Rec."Unit Price" := ItemRec."Unit Price";
                            Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
                        end;
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
                        Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec."Line Amount" := Rec.Quantity * Rec."Unit Price";
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

    procedure GetLines(var TargetLines: Record COOP_Sale_Line_Por temporary)
    begin
        TargetLines.Reset();
        TargetLines.DeleteAll();
        if Rec.FindSet() then
            repeat
                TargetLines := Rec;
                TargetLines.Insert();
            until Rec.Next() = 0;
    end;
}