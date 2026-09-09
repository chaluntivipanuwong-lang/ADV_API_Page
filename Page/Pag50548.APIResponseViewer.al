page 50548 "API Response Viewer"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'API Response Viewer';

    layout
    {
        area(Content)
        {
            // ==========================================
            // Group บน: Status & Response Headers
            // ==========================================
            group(HeaderGroup)
            {
                Caption = 'Response Status & Headers';

                field(StatusCode; ResponseStatusCode)
                {
                    ApplicationArea = All;
                    Caption = 'HTTP Status Code';
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(ResponseHeaders; ResponseHeadersText)
                {
                    ApplicationArea = All;
                    Caption = 'Response Headers';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'แสดง Headers ทั้งหมดที่ Server ส่งตอบกลับมา';
                }
            }

            // ==========================================
            // Group ล่าง: Response Body (Pretty JSON)
            // ==========================================
            group(BodyGroup)
            {
                Caption = 'Response Body (Formatted JSON)';

                field(ResponseBody; ResponseBodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Body Content';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'ข้อมูล JSON แบบ Pretty Format เว้นบรรทัดและย่อหน้าสวยงาม';
                }
            }

            // ==========================================
            // Group พารามิเตอร์: ค่าคอนฟิก URL และรหัสผ่าน
            // ==========================================
            group(RequestParameters)
            {
                Caption = 'Request Parameters';

                field(LoginURL; LoginURL)
                {
                    ApplicationArea = All;
                    Caption = 'Endpoint URL';
                }
                field(Username; Username)
                {
                    ApplicationArea = All;
                    Caption = 'Username';
                }
                field(Password; Password)
                {
                    ApplicationArea = All;
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendRequest)
            {
                ApplicationArea = All;
                Caption = 'Send API Request';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    CallAPI();
                end;
            }
            action(Swith2OAuth2)
            {
                ApplicationArea = All;
                Caption = 'Swith to OAuth2.0';
                Image = SwitchCompanies;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = page "OAuth2 Test Card";
            }
        }
    }

    trigger OnOpenPage()
    var
        wssetup: Record BasicAuthSetup;
    begin
        // 🌟 ดึงข้อมูลจากตารางจริงมาคัดลอกใส่ตารางจำลอง (Temp Table)
        wssetup.Get();

        LoginURL := wssetup."Endpoint URL";
        Username := wssetup.Username;
        Password := wssetup.Password;


    end;

    var
        ResponseStatusCode: Integer;
        ResponseHeadersText: Text;
        ResponseBodyText: Text;
        StatusStyle: Text;
        Username: Text;
        Password: Text;
        LoginURL: Text;

    local procedure CallAPI()
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        Base64Convert: Codeunit "Base64 Convert";
        AuthString: Text;
        HeaderKeys: List of [Text];
        HeaderKey: Text;
        HeaderValues: array[100] of Text;
        JToken: JsonToken;
        RawContent: Text;
        StandardJsonText: Text;
        CRLF: Text[2];

    begin
        if LoginURL = '' then
            Error('กรุณากรอก Endpoint URL ก่อนกดส่ง');

        CRLF[1] := 13;
        CRLF[2] := 10;

        Clear(ResponseStatusCode);
        Clear(ResponseHeadersText);
        Clear(ResponseBodyText);
        Clear(StatusStyle);

        if (Username <> '') or (Password <> '') then begin
            AuthString := StrSubstNo('%1:%2', Username, Password);
            RequestHeaders := Client.DefaultRequestHeaders();
            RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(AuthString));
        end;

        if Client.Get(LoginURL, ResponseMessage) then begin
            ResponseStatusCode := ResponseMessage.HttpStatusCode();

            if ResponseMessage.IsSuccessStatusCode() then
                StatusStyle := 'Favorable'
            else
                StatusStyle := 'Unfavorable';

            // แกะ Headers เรียงบรรทัด
            HeaderKeys := ResponseMessage.Headers().Keys();
            foreach HeaderKey in HeaderKeys do begin
                ResponseMessage.Headers().GetValues(HeaderKey, HeaderValues);
                if ResponseHeadersText = '' then
                    ResponseHeadersText := StrSubstNo('%1: %2', HeaderKey, HeaderValues[1])
                else
                    ResponseHeadersText += CRLF + StrSubstNo('%1: %2', HeaderKey, HeaderValues[1]);
            end;

            // ดึงข้อความดิบ
            ResponseMessage.Content().ReadAs(RawContent);

            // แปลง Unicode ไทย แล้วส่งไปจัดย่อหน้า Pretty Print
            if JToken.ReadFrom(RawContent) then begin
                JToken.WriteTo(StandardJsonText);
                ResponseBodyText := FormatPrettyJson(StandardJsonText);
            end else
                ResponseBodyText := RawContent;

        end else begin
            ResponseStatusCode := 0;
            ResponseHeadersText := '-';
            ResponseBodyText := 'ไม่สามารถเชื่อมต่อปลายทางได้ (Connection / Network Failed)';
            StatusStyle := 'Attention';
        end;
    end;

    // ฟังก์ชันจัด Indent (ย่อหน้า 2 เคาะ) และเคาะขึ้นบรรทัดใหม่อัตโนมัติ
    local procedure FormatPrettyJson(InputJson: Text): Text
    var
        i: Integer;
        c: Char;
        InQuotes: Boolean;
        IsEscaped: Boolean;
        IndentLevel: Integer;
        ResultBuilder: TextBuilder;
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        InQuotes := false;
        IndentLevel := 0;

        for i := 1 to StrLen(InputJson) do begin
            c := InputJson[i];

            // ตรวจสอบ Escape (\") โดยไม่แตะ Index ที่ 0
            IsEscaped := false;
            if i > 1 then
                if InputJson[i - 1] = '\' then
                    IsEscaped := true;

            // ตรวจสอบการเปิด-ปิดเครื่องหมายคำพูด (Quote)
            if (c = '"') and (not IsEscaped) then
                InQuotes := not InQuotes;

            if not InQuotes then
                case c of
                    '{', '[':
                        begin
                            IndentLevel += 1;
                            ResultBuilder.Append(c);
                            ResultBuilder.Append(CRLF);
                            ResultBuilder.Append(GetIndent(IndentLevel));
                        end;
                    '}', ']':
                        begin
                            if IndentLevel > 0 then
                                IndentLevel -= 1;
                            ResultBuilder.Append(CRLF);
                            ResultBuilder.Append(GetIndent(IndentLevel));
                            ResultBuilder.Append(c);
                        end;
                    ',':
                        begin
                            ResultBuilder.Append(c);
                            ResultBuilder.Append(CRLF);
                            ResultBuilder.Append(GetIndent(IndentLevel));
                        end;
                    ':':
                        begin
                            ResultBuilder.Append(': ');
                        end;
                    else
                        // กรอง Whitespace เดิมของ JSON ก้อนเดิมทิ้ง
                        if not ((c = ' ') or (c = 13) or (c = 10) or (c = 9)) then
                            ResultBuilder.Append(c);
                end
            else
                ResultBuilder.Append(c);
        end;

        exit(ResultBuilder.ToText());
    end;

    local procedure GetIndent(Level: Integer): Text
    begin
        if Level <= 0 then
            exit('');
        exit(PadStr('', Level * 2, ' '));
    end;
}