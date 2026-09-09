page 50550 "COOP_Get_Sale_Header_Por"
{
    PageType = API;
    Caption = 'Get Sale API';
    APIPublisher = 'avision';
    APIGroup = 'avapi';
    APIVersion = 'v1.0';
    EntityName = 'getsaleapi';
    EntitySetName = 'getsaleapis';
    SourceTable = COOP_Sale_Header_Por;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(documentNo; Rec."Document No.") { }
                field(customerNo; Rec."Customer No.") { }
                field(customerName; Rec."Customer Name") { }
                field(address; Rec.Address) { }
                field(country; Rec.Country) { }
                field(city; Rec.City) { }
                field(county; Rec.County) { }
                field(postCode; Rec."Post Code") { }
                field(totalAmount; Rec."Total Amount") { }

                // ผูกตาราง Line เข้ามารับ Array JSON (Nested Lines)
                part(lines; "COOP_Get_Sale_Line_Por")
                {
                    Caption = 'Lines';
                    EntityName = 'getsalelineapi';
                    EntitySetName = 'getsalelineapis';
                    SubPageLink = "Document No." = field("Document No.");
                }
            }
        }
    }
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertApiLog(Rec."Document No.", 'POST', true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        InsertApiLog(Rec."Document No.", 'PATCH/PUT', true);
    end;

    local procedure InsertApiLog(DocNo: Code[20]; TypeOfApi: Code[10]; IsSuccess: Boolean)
    var
        LogAPI: Record "Coop_LogAPI_Por";
    begin
        LogAPI.Init();
        LogAPI.CreateLog := CurrentDateTime();
        LogAPI.UpdateLog := CurrentDateTime();
        LogAPI.ApiType := TypeOfApi;
        LogAPI.SuccessLog := IsSuccess;
        LogAPI."Document No." := DocNo;
        LogAPI.Insert(true);
    end;
}