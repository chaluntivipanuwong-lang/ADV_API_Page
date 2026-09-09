xmlport 50575 "COOP Import Sale CSV"
{
    Caption = 'Import Sales with Lines from CSV';
    Format = VariableText;
    Direction = Import;
    TextEncoding = UTF8;
    UseRequestPage = false;
    FieldDelimiter = '<None>'; // ปิดการจับฟันหนู เพื่อไม่ให้อ่านข้ามบรรทัด
    FieldSeparator = ',';
    RecordSeparator = '<NewLine>';

    schema
    {
        textelement(Root)
        {
            tableelement(BufferRec; "COOP_Import_Buffer_Por")
            {
                AutoSave = false;

                textelement(DocNoText) { }
                textelement(CustNoText) { }
                textelement(CustNameText) { }
                textelement(ItemNoText) { }
                textelement(DescText) { }
                textelement(QtyText) { }
                textelement(UnitPriceText) { }

                trigger OnBeforeInsertRecord()
                var
                    ParsedQty: Decimal;
                    ParsedUnitPrice: Decimal;
                begin
                    BufferRec."Entry No." := 0;
                    BufferRec.Status := BufferRec.Status::Pending;

                    // กำจัดเครื่องหมาย " ที่อาจติดมาจากหัวท้ายข้อความ
                    BufferRec."Document No." := CopyStr(DelChr(DocNoText, '=', '"'), 1, MaxStrLen(BufferRec."Document No."));
                    BufferRec."Customer No." := CopyStr(DelChr(CustNoText, '=', '"'), 1, MaxStrLen(BufferRec."Customer No."));
                    BufferRec."Customer Name" := CopyStr(DelChr(CustNameText, '=', '"'), 1, MaxStrLen(BufferRec."Customer Name"));
                    BufferRec."Item No." := CopyStr(DelChr(ItemNoText, '=', '"'), 1, MaxStrLen(BufferRec."Item No."));
                    BufferRec.Description := CopyStr(DelChr(DescText, '=', '"'), 1, MaxStrLen(BufferRec.Description));

                    // แปลงตัวเลข
                    Evaluate(ParsedQty, DelChr(DelChr(QtyText, '=', '"'), '=', ' '));
                    Evaluate(ParsedUnitPrice, DelChr(DelChr(UnitPriceText, '=', '"'), '=', ' '));

                    BufferRec.Quantity := ParsedQty;
                    BufferRec."Unit Price" := ParsedUnitPrice;
                    BufferRec."Line Amount" := BufferRec.Quantity * BufferRec."Unit Price";
                    BufferRec."Total Amount" := BufferRec."Line Amount";

                    BufferRec.Insert(true);
                end;
            }
        }
    }
}