page 50549 "OAuth2 Test Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'OAuth 2.0 API Client';

    layout
    {
        area(Content)
        {
            // ==========================================
            // Group บน: Status & Response Headers
            // ==========================================
            group(ResponseHeaderGroup)
            {
                Caption = 'API Status & Response Headers';

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
                    ToolTip = 'แสดง Headers ที่ Server ตอบกลับมา';
                }
            }

            // ==========================================
            // Group ล่าง: Response Body (แยกเดี่ยว)
            // ==========================================
            group(ResponseBodyGroup)
            {
                Caption = 'Response Body';

                field(ResponseBody; ResponseBodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Body Content';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'ข้อมูลผลลัพธ์ (JSON/Text) ที่ Server ตอบกลับมา';
                }
            }

            // ==========================================
            // Group ตั๋ว: Access Token
            // ==========================================
            group(TokenGroup)
            {
                Caption = 'Access Token (Bearer)';

                field(AccessToken; AccessTokenText)
                {
                    ApplicationArea = All;
                    Caption = 'Current Access Token';
                    Editable = false;
                    MultiLine = true;
                }
            }

            // ==========================================
            // Group พารามิเตอร์: ค่าคอนฟิก URL และกุญแจต่างๆ
            // ==========================================
            group(SetupGroup)
            {
                Caption = 'Connection Parameters';

                field(TargetApiUrl; TargetApiUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Target Resource API URL';
                }
                field(TokenEndpoint; TokenEndpoint)
                {
                    ApplicationArea = All;
                    Caption = 'OAuth 2.0 Token URL';
                }
                field(ClientId; ClientId)
                {
                    ApplicationArea = All;
                    Caption = 'Client ID';
                }
                field(ClientSecret; ClientSecret)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret';
                    ExtendedDatatype = Masked;
                }
                field(Scope; Scope)
                {
                    ApplicationArea = All;
                    Caption = 'Scope / Resource';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FetchTokenAction)
            {
                ApplicationArea = All;
                Caption = '1. Get Access Token';
                Image = AuthorizeCreditCard;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    RequestOAuthToken();
                end;
            }

            action(CallApiAction)
            {
                ApplicationArea = All;
                Caption = '2. Call API with Token';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    CallTargetAPI();
                end;
            }
            // action(Swith2Basic)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Swith to Basic';
            //     Image = SwitchCompanies;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedOnly = true;
            //     RunObject = Page "API Response Viewer";
            // }
        }
    }

    var
        TargetApiUrl: Text;
        TokenEndpoint: Text;
        ClientId: Text;
        ClientSecret: Text;
        Scope: Text;

        AccessTokenText: Text;
        ResponseStatusCode: Integer;
        ResponseHeadersText: Text;
        ResponseBodyText: Text;
        StatusStyle: Text;
        MyTargetApiUrl: Text;
        MyAccessTkURL: Text;
        MyClientID: Text;
        MySecret: Text;
        MyScope: Text;

    trigger OnOpenPage()
    var
        OAuthSetup: Record "OAuth Setup";

    begin
        OAuthSetup.Get();
        TargetApiUrl := OAuthSetup."Target Endpoint URL";
        TokenEndpoint := OAuthSetup."Token Endpoint URL";
        ClientID := OAuthSetup."Client ID";
        ClientSecret := OAuthSetup."Client Secret";
        Scope := OAuthSetup.Scope;

    end;

    local procedure RequestOAuthToken()
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        ResponseTxt: Text;
        Payload: Text;
        JToken: JsonToken;
        JObject: JsonObject;
    begin
        if (TokenEndpoint = '') or (ClientId = '') or (ClientSecret = '') then
            Error('กรุณากรอก Token URL, Client ID และ Client Secret ให้ครบถ้วน');

        Payload := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2', ClientId, ClientSecret);
        if Scope <> '' then
            Payload += StrSubstNo('&scope=%1', Scope);

        Content.WriteFrom(Payload);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        if Client.Post(TokenEndpoint, Content, ResponseMessage) then begin
            ResponseMessage.Content().ReadAs(ResponseTxt);

            if ResponseMessage.IsSuccessStatusCode() then begin
                if JToken.ReadFrom(ResponseTxt) then begin
                    JObject := JToken.AsObject();
                    if JObject.SelectToken('access_token', JToken) then begin
                        AccessTokenText := JToken.AsValue().AsText();
                        Message('ดึง Access Token สำเร็จเรียบร้อย');
                    end else
                        Error('ไม่พบ field access_token ในผลตอบกลับ: %1', ResponseTxt);
                end;
            end else
                Error('ขอ Token ไม่สำเร็จ (HTTP %1): %2', ResponseMessage.HttpStatusCode(), ResponseTxt);
        end else
            Error('ไม่สามารถเชื่อมต่อไปยัง Token Endpoint ได้');
    end;

    local procedure CallTargetAPI()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        HeaderKeys: List of [Text];
        HeaderKey: Text;
        HeaderValues: array[100] of Text;
        JToken: JsonToken;
        RawContent: Text;
    begin
        if TargetApiUrl = '' then
            Error('กรุณากรอก Target Resource API URL ก่อนกดส่ง');

        if AccessTokenText = '' then
            Error('ยังไม่มี Access Token กรุณากดปุ่ม "1. Get Access Token" ก่อน');

        Clear(ResponseStatusCode);
        Clear(ResponseHeadersText);
        Clear(ResponseBodyText);
        Clear(StatusStyle);

        Client.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + AccessTokenText);

        if Client.Get(TargetApiUrl, ResponseMessage) then begin
            ResponseStatusCode := ResponseMessage.HttpStatusCode();

            if ResponseMessage.IsSuccessStatusCode() then
                StatusStyle := 'Favorable'
            else
                StatusStyle := 'Unfavorable';

            HeaderKeys := ResponseMessage.Headers().Keys();
            foreach HeaderKey in HeaderKeys do begin
                ResponseMessage.Headers().GetValues(HeaderKey, HeaderValues);
                if ResponseHeadersText = '' then
                    ResponseHeadersText := StrSubstNo('%1: %2', HeaderKey, HeaderValues[1])
                else
                    ResponseHeadersText += StrSubstNo('\%1: %2', HeaderKey, HeaderValues[1]);
            end;

            // 1. ดึงข้อความดิบ
            ResponseMessage.Content().ReadAs(RawContent);

            // 2. แปลง Unicode ภาษาไทย และจัดเรียงบรรทัดย่อหน้าใหม่
            if JToken.ReadFrom(RawContent) then begin
                JToken.WriteTo(RawContent); // แปลง \u0e.. กลับเป็นภาษาไทย
                ResponseBodyText := PrettyPrintJson(RawContent); // จัดระเบียบขึ้นบรรทัดใหม่
            end else
                ResponseBodyText := RawContent;

        end else begin
            ResponseStatusCode := 0;
            ResponseHeadersText := '-';
            ResponseBodyText := 'ไม่สามารถเชื่อมต่อไปยัง Target API ได้';
            StatusStyle := 'Attention';
        end;
    end;

    local procedure PrettyPrintJson(JsonText: Text): Text
    var
        i: Integer;
        c: Char;
        InQuotes: Boolean;
        IsEscaped: Boolean;
        IndentLevel: Integer;
        Result: TextBuilder;
    begin
        InQuotes := false;
        IsEscaped := false;
        IndentLevel := 0;

        for i := 1 to StrLen(JsonText) do begin
            c := JsonText[i];

            if IsEscaped then begin
                Result.Append(c);
                IsEscaped := false;
            end else if c = '\' then begin
                Result.Append(c);
                if InQuotes then
                    IsEscaped := true;
            end else if c = '"' then begin
                InQuotes := not InQuotes;
                Result.Append(c);
            end else if InQuotes then begin
                Result.Append(c);
            end else begin
                case c of
                    '{', '[':
                        begin
                            Result.Append(c);
                            IndentLevel += 1;
                            Result.AppendLine();
                            Result.Append(GetIndent(IndentLevel));
                        end;
                    '}', ']':
                        begin
                            IndentLevel -= 1;
                            Result.AppendLine();
                            Result.Append(GetIndent(IndentLevel));
                            Result.Append(c);
                        end;
                    ',':
                        begin
                            Result.Append(c);
                            Result.AppendLine();
                            Result.Append(GetIndent(IndentLevel));
                        end;
                    ':':
                        begin
                            Result.Append(': ');
                        end;
                    ' ', 9, 10, 13:
                        begin
                            // ข้ามช่องว่างเดิมที่อยู่นอกเครื่องหมายคำพูด
                        end;
                    else
                        Result.Append(c);
                end;
            end;
        end;

        exit(Result.ToText());
    end;

    local procedure GetIndent(Level: Integer): Text
    begin
        if Level <= 0 then
            exit('');
        exit(PadStr('', Level * 2, ' ')); // เคาะย่อหน้า 2 เคาะต่อ 1 ระดับชั้น
    end;
}