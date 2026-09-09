page 50572 "Basic Auth Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = BasicAuthSetup;
    Caption = 'Basic Auth Setup';
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group("Basic Auth Setup")
            {
                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                }
                field(Username; Rec.Username)
                {
                    ApplicationArea = All;
                }
                field(Password; Rec.Password)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked; // ซ่อนรหัสผ่านเป็นจุดไข่ปลา
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PullFromLSCSetup)
            {
                ApplicationArea = All;
                Caption = 'Pull from LSC Web Service Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'ดึงค่า Username และ Password มาจาก LSC Web Service Setup';

                trigger OnAction()
                var
                    LSCWSSetup: Record "LSC Web Service Setup";
                begin
                    // 1. ตรวจสอบว่าตารางต้นทางมีข้อมูลหรือไม่
                    if LSCWSSetup.Get() then begin

                        // 2. นำค่ามาใส่ใน Field ของหน้าจอนี้ (Rec)
                        Rec.Username := LSCWSSetup.Username;
                        Rec.Password := LSCWSSetup.Password;

                        // ถ้ายากดึง URL มาด้วย ก็สามารถเพิ่มบรรทัดนี้ได้:
                        // Rec."Endpoint URL" := LSCWSSetup."Login URL";

                        // 3. บันทึกลงตาราง BasicAuthSetup
                        Rec.Modify();

                        Message('ดึงข้อมูล Username และ Password มาเรียบร้อยแล้ว!');
                    end else begin
                        Error('ไม่พบข้อมูลการตั้งค่าใน LSC Web Service Setup');
                    end;
                end;
            }
        }
    }

    // สร้างข้อมูล Record ว่างๆ 1 บรรทัดรอไว้ เพื่อไม่ให้หน้าจอเป็นหน้าเปล่าตอนเปิดครั้งแรก
    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}