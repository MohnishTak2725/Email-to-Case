/**
 * @description It will handles operations for trigger over attachment
 */
public with sharing class CheckForEmailAttachmentHandler {
  
  public static Set<String> allContentVersionIds = new Set<String>();
  public static Set<String> allEmailMessageIds = new Set<String>();

  public static List<ContentVersion> allContentVersions = new List<ContentVersion>();
  public static List<ContentVersion> contentVersionsWithDocIds;
  public static List<ContentDocumentLink> allContentDocumentLinks = new List<ContentDocumentLink>();

  public static Map<String, List<ContentVersion>> allEmailMessagesWithContentVersions = new Map<String, List<ContentVersion>>();
  public static Map<String, ContentVersion> allCasesWithContentVersions = new Map<String, ContentVersion>();
  public static Map<Id, EmailMessage> incomingEmailMessagesMap = new Map<Id, EmailMessage>();
  private final static List<String> allowedFields = new List<String>();

  /**
   * @description It will get all email messages with attachment converted into content version
   * @param checkForEmailAttachmentWrap used here to remove violation of too many parameters and further used inside method for conditional handling and list of triggered attachments
   */
  public static void getAttachmentUploadedInContentVersionForPDFFileType(
    TriggerVariablesWrapper checkForEmailAttachmentWrap
  ) {
    try {
      if (
        checkForEmailAttachmentWrap.isAfter &&
        checkForEmailAttachmentWrap.isInsert
      ) {
        Set<Id> allEmailIds = new Set<Id>();
        for (Attachment atch : checkForEmailAttachmentWrap.emailAttachments) {
          allEmailIds.add(atch.ParentId);
        }

        incomingEmailMessagesMap = new Map<Id, EmailMessage>(
          [
            SELECT Id, Incoming, ParentId
            FROM EmailMessage
            WHERE Incoming = TRUE AND Id IN :allEmailIds
          ]
        );

        // Check if there are attachments from incoming email messages
        if (incomingEmailMessagesMap.size() > 0) {
          String emailMessagePrefix = Schema.SObjectType.EmailMessage.getKeyPrefix();
          for (Attachment attachment : checkForEmailAttachmentWrap.emailAttachments) {
            String parentId = attachment.ParentId;
            if (
              parentId.startsWith(emailMessagePrefix) &&
              incomingEmailMessagesMap.containsKey(attachment.ParentId)
            ) {
              ContentVersion cv = new ContentVersion();
              cv.VersionData = attachment.Body;
              cv.Title = attachment.Name;
              cv.PathOnClient = attachment.Name;
              allEmailMessageIds.add(parentId);
              if (!allEmailMessagesWithContentVersions.containsKey(parentId)) {
                allEmailMessagesWithContentVersions.put(
                  parentId,
                  new List<ContentVersion>()
                );
              }
              allEmailMessagesWithContentVersions.get(parentId).add(cv);
            }
          }

          for (Id emailMsgId : incomingEmailMessagesMap.keySet()) {
            for (
              ContentVersion conVersion : allEmailMessagesWithContentVersions.get(
                emailMsgId
              )
            ) {
              ContentVersion cv = conVersion;
              cv.Description = incomingEmailMessagesMap.get(emailMsgId)
                .ParentId;
              // cv.Description = emailMsg.ParentId;
              allCasesWithContentVersions.put(
                incomingEmailMessagesMap.get(emailMsgId).ParentId,
                cv
              );
              allContentVersions.add(cv);
            }
          }

          if (!allContentVersions.isEmpty()) {
            insert allContentVersions;
            // to reduce the time taken by current method code snippet is splits here into another method
            getAllCasesWithPDFAttachments();
          }
        }
      }
    } catch (Exception e) {
      System.debug('Generic Exception: ' + e.getMessage());
    }
  }

  /**
   * @description It will get over all content versions with triggering cases
   */
  public static void getAllCasesWithPDFAttachments() {
    for (ContentVersion cv : allContentVersions) {
      allContentVersionIds.add(cv.Id);
    }

    contentVersionsWithDocIds = [
      SELECT Id, ContentDocumentId, Description, FileType
      FROM ContentVersion
      WHERE Id IN :allContentVersionIds
    ];

    for (ContentVersion cv : contentVersionsWithDocIds) {
      if (cv.FileType == 'PDF') {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = Id.valueOf(cv.Description);
        allContentDocumentLinks.add(cdl);
      }
    }

    if (!allContentDocumentLinks.isEmpty()) {
      insert allContentDocumentLinks;
    }
  }

  public class TriggerVariablesWrapper {
    public Boolean afterTrigger;
    public Boolean insertTrigger;
    public List<Attachment> emailAttachments;
  }
}
