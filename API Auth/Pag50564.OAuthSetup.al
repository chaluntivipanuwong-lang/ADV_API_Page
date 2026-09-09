page 50564 "OAuth Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "OAuth Setup";
    Caption = 'OAuth Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General Settings';

                field("Target Endpoint URL"; Rec."Target Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'กรอก URL สำหรับขอ Access Token';
                }
                field("Token Endpoint URL"; Rec."Token Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'กรอก Token Endpoint URL';
                }
                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'กรอก Client ID จาก Azure AD';
                }
                field("Client Secret"; Rec."Client Secret")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked; // 🌟 ซ่อนรหัสเป็นจุดไข่ปลา
                    ToolTip = 'กรอก Client Secret จาก Azure AD';
                }

                field(Scope; Rec.Scope)
                {
                    ApplicationArea = All;
                    ToolTip = 'กรอก Scope';
                }
            }
        }
    }

    // 🌟 ทริกเกอร์นี้จะสร้างข้อมูลบรรทัดว่างรอไว้ให้ 1 บรรทัดอัตโนมัติเมื่อเปิดหน้าจอครั้งแรก
    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}