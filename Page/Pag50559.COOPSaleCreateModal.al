page 50559 "COOP Sale Create Modal"
{
    PageType = Card;
    Caption = 'New Sales Order (via API)';
    SourceTable = COOP_Sale_Header_Por;
    SourceTableTemporary = true; // ทำงานใน Memory
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
                    ShowMandatory = true;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;

                    trigger OnValidate()
                    var
                        Cust: Record Customer;
                    begin
                        if Cust.Get(Rec."Customer No.") then begin
                            Rec."Customer Name" := Cust.Name;
                            Rec.Address := Cust.Address;
                            Rec.City := Cust.City;
                        end;
                    end;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }
                field(Country; Rec.Country)
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
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                }
            }

            part(OrderLines; "Temp Sale Order Subform")
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
            action(SubmitApi)
            {
                ApplicationArea = All;
                Caption = 'Submit via API';
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if SendOrderToApi() then begin
                        Message('ส่งข้อมูล Sales Order %1 ผ่าน API สำเร็จ!', Rec."Document No.");
                        CurrPage.Close();
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Insert(); // สร้างหัวกระดาษเปล่าใน Memory
    end;

    local procedure SendOrderToApi(): Boolean
    var
        TempLines: Record COOP_Sale_Line_Por temporary;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        Base64Convert: Codeunit "Base64 Convert";
        RootObj: JsonObject;
        LinesArray: JsonArray;
        LineObj: JsonObject;
        JsonPayload: Text;
        ResponseText: Text;
        TotalAmount: Decimal;
    begin
        // 1. ตรวจสอบฟิลด์จำเป็น
        Rec.TestField("Document No.");
        Rec.TestField("Customer No.");

        // 2. ดึงรายการสินค้าจาก Subform ชั่วคราว
        CurrPage.OrderLines.PAGE.GetLines(TempLines);
        if TempLines.IsEmpty() then
            Error('กรุณากรอกรายการสินค้า (Line) อย่างน้อย 1 รายการ');

        // 3. วนลูปคำนวณยอดรวมและสร้าง JSON Array ของ Line
        if TempLines.FindSet() then
            repeat
                Clear(LineObj);
                LineObj.Add('itemNo', TempLines."Item No.");
                LineObj.Add('description', TempLines.Description);
                LineObj.Add('quantity', TempLines.Quantity);
                LineObj.Add('unitPrice', TempLines."Unit Price");
                TotalAmount += TempLines."Line Amount";

                LinesArray.Add(LineObj);
            until TempLines.Next() = 0;

        // 4. ประกอบ Header JSON
        RootObj.Add('documentNo', Rec."Document No.");
        RootObj.Add('customerNo', Rec."Customer No.");
        RootObj.Add('customerName', Rec."Customer Name");
        RootObj.Add('address', Rec.Address);
        RootObj.Add('country', Rec.Country);
        RootObj.Add('city', Rec.City);
        RootObj.Add('county', Rec.County);
        RootObj.Add('postCode', Rec."Post Code");

        // คีย์ลูกต้องตรงกับ EntitySetName ของ API Line (postsalelineapis)
        RootObj.Add('postsalelineapis', LinesArray);
        RootObj.WriteTo(JsonPayload);

        // 5. เตรียมยิง HTTP POST
        Content.WriteFrom(JsonPayload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json; charset=utf-8');

        RequestHeaders := Client.DefaultRequestHeaders();
        // ใช้ Basic Auth ตามข้อมูลระบบคุณ
        RequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64('COOP02:Cp123456'));

        // ส่ง POST ไปที่ API Page 50552
        if not Client.Post('http://103.28.240.184:24098/BC240_COOP/api/avision/avapi/v1.0/companies(ab11d631-dbe2-ee11-9c5b-00155ddc08a0)/postsaleapis', Content, Response) then
            Error('ไม่สามารถเชื่อมต่อไปยัง API Endpoint ได้');

        Response.Content().ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error('API Reject ข้อมูล (Status: %1)\รายละเอียด: %2', Response.HttpStatusCode(), ResponseText);

        exit(true);
    end;
}