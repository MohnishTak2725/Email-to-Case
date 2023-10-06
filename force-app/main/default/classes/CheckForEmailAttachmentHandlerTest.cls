@isTest
public class CheckForEmailAttachmentHandlerTest {
  @isTest
  static void testGetAttachmentUploadedInContentVersionForPDFFileType() {
    // Insert a test case record
    Case case1 = new Case();
    case1.Origin = 'Web';
    case1.Status = 'New';
    insert case1;

    // Create a test EmailMessage and Attachment
    EmailMessage testEmailMessage = new EmailMessage();
    testEmailMessage.Subject = 'Test Email';
    testEmailMessage.TextBody = 'Test email body';
    testEmailMessage.ParentId = case1.Id;
    testEmailMessage.Incoming = true;
    insert testEmailMessage;

    test.startTest();
    Attachment testAttachment = new Attachment();
    testAttachment.Name = 'TestAttachment.pdf';
    testAttachment.Body = Blob.valueOf('Test PDF content');
    testAttachment.ParentId = testEmailMessage.Id;
    insert testAttachment;
    test.stopTest();

    Case case2 = [
      SELECT Id, (SELECT Id FROM ContentDocumentLinks)
      FROM Case
      WHERE Id = :case1.Id
    ];

    System.assertEquals(1, case2.ContentDocumentLinks.size(), 'Size must be 1');
  }
}
