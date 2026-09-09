page 50567 "API Sales Header Subpage"
{
    PageType = ListPart;
    ApplicationArea = All;
    Caption = 'API Fetched Data';
    SourceTable = "API Sales Header Buffer";
    SourceTableTemporary = true; // 🌟 1. บังคับให้หน้านี้อ่านค่าจาก Temp Table เท่านั้น
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
            }
        }
    }

    // 🌟 2. สร้างฟังก์ชันสำหรับรับก้อนข้อมูล Temp จากหน้าหลัก มาวนลูปแสดงผล
    procedure LoadTempRecords(var TempBuffer: Record "API Sales Header Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll(); // ล้างข้อมูลเก่าบนหน้าจอก่อน

        // นำข้อมูลที่หน้าหลักยิง API ได้ มาโคลนลงใน ListPart
        if TempBuffer.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(TempBuffer);
                Rec.Insert();
            until TempBuffer.Next() = 0;

        CurrPage.Update(false);
    end;
}