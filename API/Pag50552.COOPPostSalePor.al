page 50552 "COOP_Post_Sale_Por"
{
    PageType = API;
    Caption = 'Get Sale API';
    APIPublisher = 'avision';
    APIGroup = 'avapi';
    APIVersion = 'v1.0';
    EntityName = 'postsaleapi';
    EntitySetName = 'postsaleapis';
    SourceTable = COOP_Sale_Header_Por;
    DelayedInsert = true;
    ODataKeyFields = "Document No.";

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
                part(lines; "COOP_Post_Sale_Line_Por")
                {
                    Caption = 'Lines';
                    EntityName = 'postsalelineapi';
                    EntitySetName = 'postsalelineapis';
                    SubPageLink = "Document No." = field("Document No.");
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertApiLog(Rec."Document No.", 'POST', true);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        InsertApiLog(Rec."Document No.", 'PATCH/PUT', true);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        salelines: Record COOP_Sale_Line_Por;
    begin
        salelines.SetRange("Document No.", Rec."Document No.");
        if not salelines.IsEmpty() then
            salelines.DeleteAll(false); // ใช้ false เพื่อไม่ให้ไป Trigger UpdateHeaderTotalOnDelete

        InsertApiLog(Rec."Document No.", 'DELETE', true);
        exit(true);
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