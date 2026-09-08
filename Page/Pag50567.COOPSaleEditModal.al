page 50567 "COOP Sale Edit Modal"
{
    PageType = Card;
    Caption = 'Edit Sales Order (via API)';
    SourceTable = COOP_Sale_Header_Por;
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General Information';

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field(County; Rec.County)
                {
                    ApplicationArea = All;
                }
                field(Country; Rec.Country)
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                }
            }

            // ฝัง ListPart สำหรับแก้ Line
            part(OrderLines; "Temp Sale Edit Subform")
            {
                ApplicationArea = All;
                Caption = 'Order Lines';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SubmitPatch)
            {
                ApplicationArea = All;
                Caption = 'Update via API (PATCH)';
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if SendHeaderPatch() then begin
                        SendLinesPatch();
                        Message('อัปเดตข้อมูล Sales Order %1 และรายการสินค้าผ่าน API เรียบร้อยแล้ว!', Rec."Document No.");
                        CurrPage.Close();
                    end;
                end;
            }
        }
    }

    // เรียกตอนเปิดหน้าต่าง เพื่อดึงข้อมูลเดิมขึ้นจอ
    procedure SetRecordToEdit(CurrentHeader: Record COOP_Sale_Header_Por)
    begin
        Rec.Init();
        Rec := CurrentHeader;
        Rec.Insert();

        // สั่งให้ Subform โหลดรายการ Lines ตามมา
        CurrPage.OrderLines.PAGE.LoadLinesFromDb(CurrentHeader."Document No.");
    end;

    local procedure SendHeaderPatch(): Boolean
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Base64Convert: Codeunit "Base64 Convert";
        RootObj: JsonObject;
        JsonPayload: Text;
        ResponseText: Text;
        Url: Text;
    begin
        Rec.TestField("Document No.");

        // ประกอบ JSON Body
        RootObj.Add('customerNo', Rec."Customer No.");
        RootObj.Add('customerName', Rec."Customer Name");
        RootObj.Add('address', Rec.Address);
        RootObj.Add('country', Rec.Country);
        RootObj.Add('city', Rec.City);
        RootObj.Add('county', Rec.County);
        RootObj.Add('postCode', Rec."Post Code");
        RootObj.WriteTo(JsonPayload);

        // URL เจาะจง Record
        Url := StrSubstNo(
            'http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsaleapis(''%1'')',
            Rec."Document No."
        );

        RequestMessage.Method := 'PATCH';
        RequestMessage.SetRequestUri(Url);

        // เซ็ต Body Content
        Content.WriteFrom(JsonPayload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json; charset=utf-8');
        RequestMessage.Content := Content;

        // เซ็ต Headers บน RequestMessage เท่านั้น (ไม่ใช้ DefaultRequestHeaders)
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));
        RequestHeaders.Add('If-Match', '*');

        // ส่ง Request
        if not Client.Send(RequestMessage, ResponseMessage) then
            Error('HttpClient ไม่สามารถส่งคำขอออกไปได้ ตรวจสอบ URL หรือ Firewall/Port 24098');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(ResponseText);
            Error('API Reject ข้อมูล Header (Status: %1)\รายละเอียด: %2', ResponseMessage.HttpStatusCode(), ResponseText);
        end;

        exit(true);
    end;

    // 2. วนลูปส่ง PATCH สำหรับแต่ละ Line
    local procedure SendLinesPatch()
    var
        TempLines: Record COOP_Sale_Line_Por temporary;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Base64Convert: Codeunit "Base64 Convert";
        LineObj: JsonObject;
        JsonPayload: Text;
        ResponseText: Text;
        Url: Text;
    begin
        CurrPage.OrderLines.PAGE.GetEditedLines(TempLines);

        if TempLines.FindSet() then
            repeat
                Clear(Client);
                Clear(RequestMessage);
                Clear(Content);
                Clear(LineObj);

                LineObj.Add('description', TempLines.Description);
                LineObj.Add('quantity', TempLines.Quantity);
                LineObj.Add('unitPrice', TempLines."Unit Price");
                LineObj.WriteTo(JsonPayload);

                Url := StrSubstNo(
                    'http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsalelineapis(documentNo=''%1'',lineNo=%2)',
                    TempLines."Document No.",
                    TempLines."Line No."
                );

                RequestMessage.Method := 'PATCH';
                RequestMessage.SetRequestUri(Url);

                Content.WriteFrom(JsonPayload);
                Content.GetHeaders(ContentHeaders);
                ContentHeaders.Clear();
                ContentHeaders.Add('Content-Type', 'application/json; charset=utf-8');
                RequestMessage.Content := Content;

                RequestMessage.GetHeaders(RequestHeaders);
                RequestHeaders.Clear();
                RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));
                RequestHeaders.Add('If-Match', '*');

                if Client.Send(RequestMessage, ResponseMessage) then begin
                    if not ResponseMessage.IsSuccessStatusCode() then begin
                        ResponseMessage.Content().ReadAs(ResponseText);
                        Error('API Reject ข้อมูล Line No. %1 (Status: %2)\ข้อผิดพลาด: %3', TempLines."Line No.", ResponseMessage.HttpStatusCode(), ResponseText);
                    end;
                end else
                    Error('เกิดข้อผิดพลาดในการเชื่อมต่อ Line API No. %1', TempLines."Line No.");

            until TempLines.Next() = 0;
    end;
}