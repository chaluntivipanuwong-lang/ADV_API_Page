page 50551 "COOP_Get_Sale_Line_Por"
{
    PageType = API;
    Caption = 'Get Sale API';
    APIPublisher = 'avision';
    APIGroup = 'avapi';
    APIVersion = 'v1.0';
    EntityName = 'getsalelineapi';
    EntitySetName = 'getsalelineapis';
    SourceTable = COOP_Sale_Line_Por;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(documentNo; Rec."Document No.") { }
                field(lineNo; Rec."Line No.") { }
                field(itemNo; Rec."Item No.") { }
                field(description; Rec.Description) { }
                field(quantity; Rec.Quantity) { }
                field(unitPrice; Rec."Unit Price") { }
                field(lineAmount; Rec."Line Amount") { }
            }
        }
    }
}