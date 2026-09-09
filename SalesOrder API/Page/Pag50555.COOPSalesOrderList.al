page 50555 "COOP Sales Order List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'COOP Sales Orders';
    SourceTable = COOP_Sale_Header_Por;
    Editable = false;
    CardPageId = "COOP Sale Order Card";
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(NewViaApi)
            {
                ApplicationArea = All;
                Caption = 'New Order (via API)';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    CreatePage: Page "COOP Sale Create Modal";
                begin
                    CreatePage.RunModal();
                    CurrPage.Update(false);
                end;
            }

            action(EditViaApi)
            {
                ApplicationArea = All;
                Caption = 'Edit (via API)';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    EditPage: Page "COOP Sale Edit Modal";
                begin
                    if Rec."Document No." = '' then
                        Error('กรุณาเลือกเอกสารที่ต้องการแก้ไขก่อน');

                    EditPage.SetRecordToEdit(Rec);
                    EditPage.RunModal();
                    CurrPage.Update(false);
                end;
            }

            action(DeleteViaApi)
            {
                ApplicationArea = All;
                Caption = 'Delete (via API)';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    HeaderToDelete: Record COOP_Sale_Header_Por;
                    LinesToDelete: Record COOP_Sale_Line_Por;
                begin
                    if Rec."Document No." = '' then
                        Error('กรุณาเลือกเอกสารที่ต้องการลบก่อน');

                    if not Confirm('คุณแน่ใจหรือไม่ว่าต้องการลบ Sales Order: %1 ผ่าน API?', false, Rec."Document No.") then
                        exit;

                    // 1. ส่งคำขอไปลบที่ Server ผ่าน API ก่อน
                    if SendDeleteToApi(Rec."Document No.") then begin
                        // 2. เมื่อ Server ตอบรับ 200/204 OK ค่อยมาลบ Record ในตาราง Local ทั้ง Header และ Line
                        LinesToDelete.SetRange("Document No.", Rec."Document No.");
                        if not LinesToDelete.IsEmpty() then
                            LinesToDelete.DeleteAll(true);

                        if HeaderToDelete.Get(Rec."Document No.") then
                            HeaderToDelete.Delete(true);

                        Message('ลบข้อมูล Sales Order %1 ผ่าน API สำเร็จ!', Rec."Document No.");
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(ImportViaApi)
            {
                ApplicationArea = All;
                Caption = 'Sync Data (GET API)';
                Image = ImportDatabase;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if Confirm('คุณต้องการดึงข้อมูล Sales Order ล่าสุดจาก Server (API) ใช่หรือไม่?', true) then begin
                        ImportDataFromApi();
                        Message('ดึงข้อมูลจาก API เสร็จสมบูรณ์');
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(ImportFromCsv)
            {
                ApplicationArea = All;
                Caption = 'Import from CSV';
                Image = ImportExcel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    InStreamFile: InStream;
                    FromFileName: Text;
                begin
                    if UploadIntoStream('เลือกไฟล์ CSV สำหรับนำเข้า', '', 'CSV Files (*.csv)|*.csv', FromFileName, InStreamFile) then begin
                        Xmlport.Import(Xmlport::"COOP Import Sale CSV", InStreamFile);
                        Message('นำเข้าไฟล์ %1 เข้าสู่ Buffer เรียบร้อยแล้ว', FromFileName);
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(GoToImportBuffer)
            {
                ApplicationArea = All;
                Caption = 'Go to Import Buffer List';
                Image = GetSourceDoc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"COOP Import Buffer List");
                end;
            }
        }
    }

    local procedure SendDeleteToApi(DocNo: Code[20]): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Base64Convert: Codeunit "Base64 Convert";
        Url: Text;
        ResponseText: Text;
    begin
        Url := StrSubstNo('http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsaleapis(''%1'')', DocNo);

        RequestMessage.Method := 'DELETE';
        RequestMessage.SetRequestUri(Url);

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));

        // แก้ปัญหา 409 Conflict โดยบังคับให้เพิกเฉยต่อความขัดแย้งของ ETag / Timestamp
        RequestHeaders.Add('If-Match', '*');

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error('ไม่สามารถเชื่อมต่อไปยัง API Endpoint ได้');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(ResponseText);
            Error('API Reject การลบข้อมูล (Status: %1)\รายละเอียด: %2', ResponseMessage.HttpStatusCode(), ResponseText);
        end;

        exit(true);
    end;

    local procedure ImportDataFromApi()
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Base64Convert: Codeunit "Base64 Convert";
        Url: Text;
        ResponseText: Text;
        RootObj: JsonObject;
        ValueToken: JsonToken;
        OrderArray: JsonArray;
        OrderToken: JsonToken;
        OrderObj: JsonObject;
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        PropToken: JsonToken;
        HeaderRec: Record COOP_Sale_Header_Por;
        LineRec: Record COOP_Sale_Line_Por;
    begin
        Url := 'http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsaleapis?$expand=postsalelineapis';

        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(Url);

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error('ไม่สามารถเชื่อมต่อไปยัง API Endpoint (GET) ได้');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(ResponseText);
            Error('API Reject ข้อมูล (Status: %1)\รายละเอียด: %2', ResponseMessage.HttpStatusCode(), ResponseText);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);

        if not RootObj.ReadFrom(ResponseText) then
            Error('รูปแบบ JSON ที่ส่งกลับมาไม่ถูกต้อง');

        if not RootObj.Get('value', ValueToken) then
            exit;

        OrderArray := ValueToken.AsArray();

        foreach OrderToken in OrderArray do begin
            OrderObj := OrderToken.AsObject();
            OrderObj.Get('documentNo', PropToken);

            if not HeaderRec.Get(PropToken.AsValue().AsCode()) then begin
                HeaderRec.Init();
                HeaderRec."Document No." := PropToken.AsValue().AsCode();
                HeaderRec.Insert(true);
            end;

            if OrderObj.Get('customerNo', PropToken) then HeaderRec."Customer No." := PropToken.AsValue().AsCode();
            if OrderObj.Get('customerName', PropToken) then HeaderRec."Customer Name" := PropToken.AsValue().AsText();
            if OrderObj.Get('address', PropToken) then HeaderRec.Address := PropToken.AsValue().AsText();
            if OrderObj.Get('city', PropToken) then HeaderRec.City := PropToken.AsValue().AsText();
            if OrderObj.Get('county', PropToken) then HeaderRec.County := PropToken.AsValue().AsText();
            if OrderObj.Get('country', PropToken) then HeaderRec.Country := PropToken.AsValue().AsCode();
            if OrderObj.Get('postCode', PropToken) then HeaderRec."Post Code" := PropToken.AsValue().AsInteger();
            if OrderObj.Get('totalAmount', PropToken) then HeaderRec."Total Amount" := PropToken.AsValue().AsDecimal();
            HeaderRec.Modify(true);

            if OrderObj.Get('postsalelineapis', LinesToken) then begin
                LinesArray := LinesToken.AsArray();
                foreach LineToken in LinesArray do begin
                    LineObj := LineToken.AsObject();
                    LineObj.Get('lineNo', PropToken);

                    if not LineRec.Get(HeaderRec."Document No.", PropToken.AsValue().AsInteger()) then begin
                        LineRec.Init();
                        LineRec."Document No." := HeaderRec."Document No.";
                        LineRec."Line No." := PropToken.AsValue().AsInteger();
                        LineRec.Insert(true);
                    end;

                    if LineObj.Get('itemNo', PropToken) then LineRec."Item No." := PropToken.AsValue().AsCode();
                    if LineObj.Get('description', PropToken) then LineRec.Description := PropToken.AsValue().AsText();
                    if LineObj.Get('quantity', PropToken) then LineRec.Quantity := PropToken.AsValue().AsDecimal();
                    if LineObj.Get('unitPrice', PropToken) then LineRec."Unit Price" := PropToken.AsValue().AsDecimal();
                    if LineObj.Get('lineAmount', PropToken) then LineRec."Line Amount" := PropToken.AsValue().AsDecimal();

                    LineRec.Modify(true);
                end;
            end;
        end;
    end;
}