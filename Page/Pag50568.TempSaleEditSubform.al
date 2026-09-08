page 50568 "Temp Sale Edit Subform"
{
    PageType = ListPart;
    Caption = 'Order Lines';
    SourceTable = COOP_Sale_Line_Por;
    SourceTableTemporary = true; // เก็บใน RAM ไม่บันทึกตรงลง DB
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false; // รหัสสินค้าไม่ควรแก้ ถ้าจะแก้ควรเป็นการลบ/เพิ่ม
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

    // ฟังก์ชันโหลด Line จาก Database จริง เข้ามาพักไว้ใน Temp Record
    procedure LoadLinesFromDb(DocNo: Code[20])
    var
        RealLines: Record COOP_Sale_Line_Por;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        RealLines.SetRange("Document No.", DocNo);
        if RealLines.FindSet() then
            repeat
                Rec := RealLines;
                Rec.Insert();
            until RealLines.Next() = 0;

        CurrPage.Update(false);
    end;

    // ฟังก์ชันส่ง Temp Line ที่แก้แล้ว ออกไปให้หน้าแม่วนลูปยิง API
    procedure GetEditedLines(var TargetLines: Record COOP_Sale_Line_Por temporary)
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
