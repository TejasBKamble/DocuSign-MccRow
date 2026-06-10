/**
 * @description       : Service to get the message store from RingCentral
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 12-29-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralGetMessageStoreService {
    // Returns the unique ID of this SMS send
    public static ServiceResponse getMessageStore(API_Event__c event)
    {
        Integer page = 1;
        Integer totalPages;

        ServiceResponse sr = new ServiceResponse();
        List<RingCentral_Message__c> messages = new List<RingCentral_Message__c>();
        sr.eventId = event.Id;
        try
        {
            //Loop through pages until totalPages is reached
            do
            {
                RingCentralCalloutGetMessageStore call = new RingCentralCalloutGetMessageStore(event, page);
                HttpResponse res = call.doCallout();
                sr.responseBody = res.getBody();

                if ( !(res.getStatusCode() >= 200 && res.getStatusCode() < 300) )
                {
                    throw new RingCentralCallout.RingCentralCalloutException('Status code: ' + res.getStatusCode() + '.\nResponse: ' + res.getBody()+'.');
                }

                Map<String,Object> messagesMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

                Map<String,Object> pagingMap = messagesMap.get('paging') != null ? (Map<String,Object>) messagesMap.get('paging') : null;
                //If Paging Map is null, break the loop
                if (pagingMap == null || pagingMap.size() == 0)
                {
                    break;
                }

                totalPages = pagingMap.get('totalPages') != null ? (Integer) pagingMap.get('totalPages') : 1;
                page = pagingMap.get('page') != null ? (Integer) pagingMap.get('page') : 1;

                //If Records List size is 0, break the loop
                List<Object> records = messagesMap.get('records') != null ? (List<Object>) messagesMap.get('records') : null;
                if (records == null || records.size() == 0)
                {
                    break;
                }

                //For each record, create a new message record, store it in the messages list, return the messages list as part of the Service Response Object
                for (Object record : records)
                {
                    Map<String,Object> recordMap = (Map<String,Object>) record;
                    RingCentral_Message__c message = new RingCentral_Message__c();
                    message.API_Event_ID__c = event.Id;
                    message.RingCentral_Message_Id__c = recordMap.get('id') != null ? String.valueOf(recordMap.get('id')) : null;
                    message.RingCentral_Message_Link__c = recordMap.get('uri') != null ? (String) recordMap.get('uri') : null;

                    //Fix this to be the correct datetime format, Raw example: 2016-03-10T18:07:52.534Z
                    //Formatted input string example: 2016-03-10 18:07:52
                    String smsDeliveryTime = (String) recordMap.get('smsDeliveryTime');
                    if (smsDeliveryTime != null)
                    {
                        //Fix this to be the correct datetime format before converting to a DateTime object, Formatted input string example: 2016-03-10 18:07:52
                        //Then convert to a DateTime object and format to the correct datetime format
                        smsDeliveryTime = smsDeliveryTime.replace('T', ' ');
                        //Replace all after Seconds with ''
                        smsDeliveryTime = smsDeliveryTime.substringBeforeLast('.');
                        message.smsDeliveryTime__c = DateTime.valueOf(smsDeliveryTime);
                    } else {
                        message.smsDeliveryTime__c = null;
                    }
                    
                    String creationTime = (String)recordMap.get('creationTime');
                    if (creationTime != null)
                    {
                        //Fix this to be the correct datetime format before converting to a DateTime object, Formatted input string example: 2016-03-10 18:07:52
                        //Then convert to a DateTime object and format to the correct datetime format
                        creationTime = creationTime.replace('T', ' ');
                        //Replace all after Seconds with ''
                        creationTime = creationTime.substringBeforeLast('.');
                        message.RingCentral_CreationTime__c = DateTime.valueOf(creationTime);
                    }
                    else
                    {
                        message.RingCentral_CreationTime__c = null;
                    }

                    message.Message_Body__c = recordMap.get('subject') != null ? (String) recordMap.get('subject') : null;
                    message.Conversation_ID__c = recordMap.get('conversationId') != null ? String.valueOf(recordMap.get('conversationId')) : null;
                    message.Direction__c = recordMap.get('direction') != null ? (String) recordMap.get('direction') : null;
                    message.Message_Status__c = recordMap.get('messageStatus') != null ? (String) recordMap.get('messageStatus') : null;

                    List<Object> recordAttachments = recordMap.get('attachments') != null ? (List<Object>) recordMap.get('attachments') : null;
                    if (recordAttachments != null && recordAttachments.size() > 0)
                    {
                        //Loop through the attachments and add the link to the Attachment_Links__c field, line break separated.
                        //If the attachment link is null, continue to the next attachment.
                        //If the attachment link is not null, add it to the Attachment_Links__c field, line break separated.
                        //Dont add a line break after the last attachment link.  Don't add a line break if only 1 attachment.
                        String attachmentLinks = '';
                        for (Integer i = 0; i < recordAttachments.size(); i++)
                        {
                            Map<String,Object> attachmentMap = (Map<String,Object>) recordAttachments[i];
                            String attachmentLink = attachmentMap.get('uri') != null ? (String) attachmentMap.get('uri') : null;
                            if (attachmentLink != null)
                            {
                                if (i < recordAttachments.size() - 1)
                                {
                                    attachmentLinks += attachmentLink + '\n';
                                }
                                else
                                {
                                    attachmentLinks += attachmentLink;
                                }
                            }
                        }
                        message.Attachment_Links__c = attachmentLinks;
                    }

                    Map<String,Object> recordFrom = recordMap.get('from') != null ? (Map<String,Object>) recordMap.get('from') : null;
                    if (recordFrom != null)
                    {
                        message.From_Phone_Number__c = recordFrom.get('phoneNumber') != null ? (String) recordFrom.get('phoneNumber') : null;
                    }

                    //Loop through the attachments and add the link to the Attachment_Links__c field, comma separated.
                    //If the attachment link is null, continue to the next attachment.
                    //If the attachment link is not null, add it to the Attachment_Links__c field, comma separated.
                    //Dont add a comma after the last attachment link.  Don't add a comma if only 1 attachment.
                    String toPhoneNumbers = '';
                    List<Object> recordTo = recordMap.get('to') != null ? (List<Object>) recordMap.get('to') : null;
                    if (recordTo != null && recordTo.size() > 0)
                    {
                        for (Integer i = 0; i < recordTo.size(); i++)
                        {
                            Map<String,Object> recordToItem = (Map<String,Object>) recordTo.get(i);
                            String toPhoneNumber = recordToItem.get('phoneNumber') != null ? (String) recordToItem.get('phoneNumber') : null;
                            if (toPhoneNumber != null)
                            {
                                if (i < recordTo.size() - 1)
                                {
                                    toPhoneNumbers += toPhoneNumber + ',';
                                }
                                else
                                {
                                    toPhoneNumbers += toPhoneNumber;
                                }
                            }
                        }
                        message.To_Phone_Number_s__c = toPhoneNumbers;
                    }

                    messages.add(message);
                }
                
            } while (page < totalPages);

            if (messages.isEmpty())
            {
                throw new RingCentralGetMessageStoreQueueable.RingCentralGetMessageStoreException('No messages created');
            }
        }
        catch(Exception e) {
            sr.isSuccess = false;
            sr.errorMessage = e.getMessage() + '\nStackTrace: ' + e.getStackTraceString() + '.\n';
        }

        sr.messages = messages;

        return sr;
    }

    public class ServiceResponse
    {
        public Boolean isSuccess;
        public String errorMessage;
        public List<RingCentral_Message__c> messages;
        public String eventId;
        public String responseBody;

        public ServiceResponse()
        {
            this.isSuccess = true;
            this.errorMessage = ' ';
            this.messages = new List<RingCentral_Message__c>();
            this.eventId = '';
            this.responseBody = ' ';
        }
    }

    /*
    //Example response body for message store callout:
    {
        "uri":"https://platform.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store?direction=Inbound&readStatus=Unread&availability=Alive&dateFrom=2018-09-17T12:53:00.000Z&page=1&perPage=2",
        "records":[
            {
                "uri":"https://platform.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store/402406986008",
                "id":402406986008,
                "to":[
                    {
                    "name":"Jane Smith"
                    }
                ],
                "from":{
                    "phoneNumber":"+18888984591",
                    "name":"RingCentral"
                },
                "type":"VoiceMail",
                "creationTime":"2018-09-18T09:24:04.000Z",
                "readStatus":"Unread",
                "priority":"Normal",
                "attachments":[
                    {
                    "id":402406986008,
                    "uri":"https://media.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store/402406986008/content/402406986008",
                    "type":"AudioRecording",
                    "contentType":"audio/wav",
                    "vmDuration":42
                    }
                ],
                "direction":"Inbound",
                "availability":"Alive",
                "subject":"Welcome to RingCentral!",
                "messageStatus":"Received",
                "lastModifiedTime":"2018-09-18T09:24:04.102Z",
                "vmTranscriptionStatus":"NotAvailable"
            },
            {
                "uri":"https://platform.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store/402406984008",
                "id":402406984008,
                "to":[
                    {
                    "name":"Jane Smith"
                    }
                ],
                "from":{
                    "phoneNumber":"+18442058517",
                    "name":"RingCentral"
                },
                "type":"VoiceMail",
                "creationTime":"2018-09-18T09:24:03.000Z",
                "readStatus":"Unread",
                "priority":"Normal",
                "attachments":[
                    {
                    "id":402406984008,
                    "uri":"https://media.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store/402406984008/content/402406984008",
                    "type":"AudioRecording",
                    "contentType":"audio/wav",
                    "vmDuration":25
                    }
                ],
                "direction":"Inbound",
                "availability":"Alive",
                "messageStatus":"Received",
                "lastModifiedTime":"2018-09-18T09:24:03.531Z",
                "vmTranscriptionStatus":"NotAvailable"
            }
        ],
        "paging":{
            "page":1,
            "totalPages":1,
            "perPage":2,
            "totalElements":2,
            "pageStart":0,
            "pageEnd":1
        },
        "navigation":{
            "firstPage":{
                "uri":"https://platform.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store?direction=Inbound&readStatus=Unread&availability=Alive&dateFrom=2018-09-17T12:53:00.000Z&page=1&perPage=2"
            },
            "lastPage":{
                "uri":"https://platform.ringcentral.com/restapi/v1.0/account/401928394008/extension/401928394008/message-store?direction=Inbound&readStatus=Unread&availability=Alive&dateFrom=2018-09-17T12:53:00.000Z&page=1&perPage=2"
            }
        }
        }
    */
}