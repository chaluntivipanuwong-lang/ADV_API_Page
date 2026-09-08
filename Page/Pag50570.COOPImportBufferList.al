page 50570 "COOP Import Buffer List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Sales Order Import Buffer';
    SourceTable = "COOP_Import_Buffer_Por";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Style = Attention;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportCsv)
            {
                ApplicationArea = All;
                Caption = 'Upload CSV';
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
                        CurrPage.Update(false);
                        Message('นำเข้าไฟล์ %1 เข้าสู่ Buffer เรียบร้อยแล้ว', FromFileName);
                    end;
                end;
            }

            action(FetchFromApi)
            {
                ApplicationArea = All;
                Caption = '1. Fetch API to Buffer';
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    FetchApiToBuffer();
                    CurrPage.Update(false);
                end;
            }

            action(ProcessBuffer)
            {
                ApplicationArea = All;
                Caption = '2. Process to Real Tables';
                Image = PostApplication;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    ProcessBufferToRealTables();
                    CurrPage.Update(false);
                end;
            }

            action(ResetToPending)
            {
                ApplicationArea = All;
                Caption = 'Reset to Pending';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'คืนค่าแถวที่ Error หรือ Skipped ให้กลับมาเป็น Pending เพื่อลองประมวลผลใหม่';

                trigger OnAction()
                var
                    SelectedBuffer: Record "COOP_Import_Buffer_Por";
                    CountUpdated: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedBuffer);
                    if SelectedBuffer.FindSet() then
                        repeat
                            if SelectedBuffer.Status in [SelectedBuffer.Status::Error, SelectedBuffer.Status::Skipped, SelectedBuffer.Status::Draft] then begin
                                SelectedBuffer.Status := SelectedBuffer.Status::Pending;
                                SelectedBuffer."Error Message" := '';
                                SelectedBuffer.Modify();
                                CountUpdated += 1;
                            end;
                        until SelectedBuffer.Next() = 0;

                    CurrPage.Update(false);
                    Message('เปลี่ยนสถานะเป็น Pending เรียบร้อยแล้ว %1 รายการ', CountUpdated);
                end;
            }

            action(SkipRecord)
            {
                ApplicationArea = All;
                Caption = 'Skip / Unskip';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'สลับสถานะเป็น Skipped เพื่อข้ามรายการนี้ไม่ให้นำเข้าตารางจริง';

                trigger OnAction()
                var
                    SelectedBuffer: Record "COOP_Import_Buffer_Por";
                begin
                    CurrPage.SetSelectionFilter(SelectedBuffer);
                    if SelectedBuffer.FindSet() then
                        repeat
                            if SelectedBuffer.Status = SelectedBuffer.Status::Skipped then
                                SelectedBuffer.Status := SelectedBuffer.Status::Pending
                            else if SelectedBuffer.Status <> SelectedBuffer.Status::Processed then
                                SelectedBuffer.Status := SelectedBuffer.Status::Skipped;

                            SelectedBuffer.Modify();
                        until SelectedBuffer.Next() = 0;

                    CurrPage.Update(false);
                end;
            }

            action(GoToSaleOrder)
            {
                ApplicationArea = All;
                Caption = 'Go to Sale Order';
                Image = GetSourceDoc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"COOP Sales Order List");
                end;
            }
            action(ClearSelectedBuffer)
            {
                ApplicationArea = All;
                Caption = 'Clear Selected';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'ลบเฉพาะรายการที่เลือกในตาราง Buffer ออก';

                trigger OnAction()
                var
                    SelectedBuffer: Record "COOP_Import_Buffer_Por";
                    DeletedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedBuffer);
                    if SelectedBuffer.IsEmpty() then
                        Error('กรุณาเลือกรายการที่ต้องการลบก่อน');

                    if Confirm('คุณต้องการลบรายการใน Buffer ที่เลือกไว้ใช่หรือไม่?', false) then begin
                        DeletedCount := SelectedBuffer.Count();
                        SelectedBuffer.DeleteAll(true);
                        CurrPage.Update(false);
                        Message('ลบข้อมูลใน Buffer ที่เลือกสำเร็จ %1 รายการ', DeletedCount);
                    end;
                end;
            }

            // ==========================================
            // ปุ่มที่ 2: เคลียร์ข้อมูลทั้งหมดใน Buffer (ล้างตาราง)
            // ==========================================
            action(ClearAllBuffer)
            {
                ApplicationArea = All;
                Caption = 'Clear All Buffer';
                Image = ClearLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'ลบข้อมูลทั้งหมดในตาราง Buffer';

                trigger OnAction()
                var
                    AllBuffer: Record "COOP_Import_Buffer_Por";
                begin
                    if AllBuffer.IsEmpty() then begin
                        Message('ไม่มีข้อมูลใน Buffer ให้ลบ');
                        exit;
                    end;

                    // ป้องกันการเผลอกด ด้วยการถามยืนยันแบบบังคับเลือก No เป็นค่าเริ่มต้น
                    if Confirm('คำเตือน: คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลทั้งหมดใน Buffer (%1 รายการ)?', false, AllBuffer.Count()) then begin
                        AllBuffer.DeleteAll(true);
                        CurrPage.Update(false);
                        Message('ล้างข้อมูลทั้งหมดใน Buffer เรียบร้อยแล้ว');
                    end;
                end;
            }
            action(ClearProcessed)
            {
                ApplicationArea = All;
                Caption = 'Clear Processed Only';
                Image = Archive;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'ลบเฉพาะรายการที่ประมวลผลเสร็จแล้ว (Processed) ออกจาก Buffer';

                trigger OnAction()
                var
                    ProcessedBuffer: Record "COOP_Import_Buffer_Por";
                    CountDeleted: Integer;
                begin
                    ProcessedBuffer.SetRange(Status, ProcessedBuffer.Status::Processed);
                    if ProcessedBuffer.IsEmpty() then begin
                        Message('ไม่มีรายการที่สถานะเป็น Processed ให้ลบ');
                        exit;
                    end;

                    CountDeleted := ProcessedBuffer.Count();
                    ProcessedBuffer.DeleteAll(true);
                    CurrPage.Update(false);
                    Message('ลบรายการที่ประมวลผลเสร็จแล้ว %1 รายการ', CountDeleted);
                end;
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Processed:
                StatusStyle := 'Favorable';     // สีเขียว
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';   // สีแดง
            Rec.Status::Pending:
                StatusStyle := 'Ambiguous';     // สีเหลือง/ส้ม
            Rec.Status::Processing:
                StatusStyle := 'StrongAccent';  // สีน้ำเงินตัวหนา
            Rec.Status::Skipped:
                StatusStyle := 'Subordinate';   // สีเทา
            else
                StatusStyle := 'None';          // สีข้อความปกติ (Draft)
        end;
    end;

    local procedure FetchApiToBuffer()
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
        PropToken: JsonToken;
        BufferRec: Record "COOP_Import_Buffer_Por";
        OutStrm: OutStream;
        DocNoText: Text;
        InsertedCount: Integer;
    begin
        Url := 'http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsaleapis?$expand=postsalelineapis';

        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(Url);

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error('ไม่สามารถเชื่อมต่อไปยัง API Endpoint ได้');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(ResponseText);
            Error('API Reject: %1', ResponseText);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);

        if not RootObj.ReadFrom(ResponseText) then
            Error('JSON รูปแบบไม่ถูกต้อง');

        if not RootObj.Get('value', ValueToken) then
            exit;

        OrderArray := ValueToken.AsArray();

        foreach OrderToken in OrderArray do begin
            OrderObj := OrderToken.AsObject();
            OrderObj.Get('documentNo', PropToken);
            DocNoText := PropToken.AsValue().AsCode();

            BufferRec.Reset();
            BufferRec.SetRange("Document No.", DocNoText);
            if BufferRec.IsEmpty() then begin
                BufferRec.Init();
                BufferRec."Document No." := CopyStr(DocNoText, 1, MaxStrLen(BufferRec."Document No."));

                if OrderObj.Get('customerNo', PropToken) then
                    BufferRec."Customer No." := PropToken.AsValue().AsCode();
                if OrderObj.Get('customerName', PropToken) then
                    BufferRec."Customer Name" := CopyStr(PropToken.AsValue().AsText(), 1, MaxStrLen(BufferRec."Customer Name"));
                if OrderObj.Get('totalAmount', PropToken) then
                    BufferRec."Total Amount" := PropToken.AsValue().AsDecimal();

                BufferRec.Status := BufferRec.Status::Pending;

                BufferRec."Raw Payload".CreateOutStream(OutStrm);
                OrderObj.WriteTo(OutStrm);

                BufferRec.Insert(true);
                InsertedCount += 1;
            end;
        end;

        Message('ดึงข้อมูลลง Buffer สำเร็จ %1 รายการ', InsertedCount);
    end;

    local procedure ProcessBufferToRealTables()
    var
        BufferRec: Record "COOP_Import_Buffer_Por";
        UpdateBuffer: Record "COOP_Import_Buffer_Por";
        HeaderRec: Record COOP_Sale_Header_Por;
        LineRec: Record COOP_Sale_Line_Por;
        LastLineRec: Record COOP_Sale_Line_Por;
        InStrm: InStream;
        JsonText: Text;
        OrderObj: JsonObject;
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        PropToken: JsonToken;
        NextLineNo: Integer;
        ProcessedCount: Integer;
    begin
        BufferRec.Reset();
        BufferRec.SetRange(Status, BufferRec.Status::Pending);

        if not BufferRec.FindSet() then begin
            Message('ไม่มีรายการที่อยู่ในสถานะ Pending ให้ประมวลผล');
            exit;
        end;

        repeat
            BufferRec.CalcFields("Raw Payload");

            // ==========================================
            // กรณีที่ 1: มาจาก API (มี Raw Payload เป็น JSON)
            // ==========================================
            if BufferRec."Raw Payload".HasValue() then begin
                BufferRec."Raw Payload".CreateInStream(InStrm);
                InStrm.ReadText(JsonText);

                if OrderObj.ReadFrom(JsonText) then begin
                    if not HeaderRec.Get(BufferRec."Document No.") then begin
                        HeaderRec.Init();
                        HeaderRec."Document No." := BufferRec."Document No.";
                        HeaderRec.Insert(false);
                    end;

                    HeaderRec."Customer No." := BufferRec."Customer No.";
                    HeaderRec."Customer Name" := BufferRec."Customer Name";
                    if OrderObj.Get('address', PropToken) then HeaderRec.Address := PropToken.AsValue().AsText();
                    if OrderObj.Get('city', PropToken) then HeaderRec.City := PropToken.AsValue().AsText();
                    if OrderObj.Get('county', PropToken) then HeaderRec.County := PropToken.AsValue().AsText();
                    if OrderObj.Get('country', PropToken) then HeaderRec.Country := PropToken.AsValue().AsCode();
                    if OrderObj.Get('postCode', PropToken) then HeaderRec."Post Code" := PropToken.AsValue().AsInteger();
                    HeaderRec."Total Amount" := BufferRec."Total Amount";
                    HeaderRec.Modify(false);

                    if OrderObj.Get('postsalelineapis', LinesToken) then begin
                        LinesArray := LinesToken.AsArray();
                        foreach LineToken in LinesArray do begin
                            LineObj := LineToken.AsObject();
                            LineObj.Get('lineNo', PropToken);

                            if not LineRec.Get(HeaderRec."Document No.", PropToken.AsValue().AsInteger()) then begin
                                LineRec.Init();
                                LineRec."Document No." := HeaderRec."Document No.";
                                LineRec."Line No." := PropToken.AsValue().AsInteger();
                                LineRec.Insert(false);
                            end;

                            if LineObj.Get('itemNo', PropToken) then LineRec."Item No." := PropToken.AsValue().AsCode();
                            if LineObj.Get('description', PropToken) then LineRec.Description := PropToken.AsValue().AsText();
                            if LineObj.Get('quantity', PropToken) then LineRec.Quantity := PropToken.AsValue().AsDecimal();
                            if LineObj.Get('unitPrice', PropToken) then LineRec."Unit Price" := PropToken.AsValue().AsDecimal();
                            if LineObj.Get('lineAmount', PropToken) then LineRec."Line Amount" := PropToken.AsValue().AsDecimal();
                            LineRec.Modify(false);
                        end;
                    end;

                    if UpdateBuffer.Get(BufferRec."Entry No.") then begin
                        UpdateBuffer.Status := UpdateBuffer.Status::Processed;
                        UpdateBuffer."Error Message" := '';
                        UpdateBuffer.Modify();
                    end;
                    ProcessedCount += 1;
                end;
            end
            // ==========================================
            // กรณีที่ 2: มาจาก CSV (มีข้อมูล Line อยู่ใน Buffer แต่ละแถว)
            // ==========================================
            else begin
                // 1. ตรวจสอบ/สร้าง Header
                if not HeaderRec.Get(BufferRec."Document No.") then begin
                    HeaderRec.Init();
                    HeaderRec."Document No." := BufferRec."Document No.";
                    HeaderRec."Customer No." := BufferRec."Customer No.";
                    HeaderRec."Customer Name" := BufferRec."Customer Name";
                    HeaderRec."Total Amount" := 0;
                    HeaderRec.Insert(false);
                end;

                // 2. หารหัส Line No. ถัดไป (10000, 20000, 30000...)
                LastLineRec.Reset();
                LastLineRec.SetRange("Document No.", BufferRec."Document No.");
                if LastLineRec.FindLast() then
                    NextLineNo := LastLineRec."Line No." + 10000
                else
                    NextLineNo := 10000;

                // 3. บันทึกบรรทัด Line
                LineRec.Init();
                LineRec."Document No." := BufferRec."Document No.";
                LineRec."Line No." := NextLineNo;
                LineRec."Item No." := BufferRec."Item No.";
                LineRec.Description := BufferRec.Description;
                LineRec.Quantity := BufferRec.Quantity;
                LineRec."Unit Price" := BufferRec."Unit Price";

                if (BufferRec."Line Amount" = 0) and (BufferRec.Quantity <> 0) and (BufferRec."Unit Price" <> 0) then
                    LineRec."Line Amount" := BufferRec.Quantity * BufferRec."Unit Price"
                else
                    LineRec."Line Amount" := BufferRec."Line Amount";

                LineRec.Insert(false);

                // 4. สะสมยอดกลับไปที่ Header
                HeaderRec."Total Amount" += LineRec."Line Amount";
                HeaderRec.Modify(false);

                // 5. อัปเดตสถานะใน Buffer เป็น Processed
                if UpdateBuffer.Get(BufferRec."Entry No.") then begin
                    UpdateBuffer.Status := UpdateBuffer.Status::Processed;
                    UpdateBuffer."Error Message" := '';
                    UpdateBuffer.Modify();
                end;

                ProcessedCount += 1;
            end;

        until BufferRec.Next() = 0;

        Message('ประมวลผลย้ายข้อมูลเข้าตารางจริงสำเร็จ %1 รายการ', ProcessedCount);
    end;
}