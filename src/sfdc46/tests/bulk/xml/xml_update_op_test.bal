// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["testXmlUpsertOperator"]
}
function testXmlUpdateOperator() {
    log:printInfo("salesforceBulkClient -> XmlUpdateOperator");

    string lucasID = getContactIdByName("Lucas", "Podolski", "Professor Grade 05");
    string kloseID = getContactIdByName("Miroslav", "Klose", "Professor Grade 05");

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${lucasID}</Id>
            <FirstName>Lucas</FirstName>
            <LastName>Podolski</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0332254123</Phone>
            <Email>lucas@w3c.com</Email>
            <My_External_Id__c>221</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${kloseID}</Id>
            <FirstName>Miroslav</FirstName>
            <LastName>Klose</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442554423</Phone>
            <Email>klose@w3c.com</Email>
            <My_External_Id__c>222</My_External_Id__c>
        </sObject>
    </sObjects>`;

    // Create JSON update operator.
    XmlUpdateOperator|ConnectorError xmlUpdateOperator = sfBulkClient->createXmlUpdateOperator("Contact");

    if (xmlUpdateOperator is XmlUpdateOperator) {
        string batchIdUsingXml = EMPTY_STRING;

        // Upload the json contacts.
        BatchInfo|ConnectorError batchUsingXml = xmlUpdateOperator->update(<@untainted> contacts);
        if (batchUsingXml is BatchInfo) {
            test:assertTrue(batchUsingXml.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingXml = batchUsingXml.id;
        } else {
            test:assertFail(msg = batchUsingXml.detail()?.message.toString());
        }

        // Get job information.
        JobInfo|ConnectorError job = xmlUpdateOperator->getJobInfo();
        if (job is JobInfo) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.detail()?.message.toString());
        }

        // Close job.
        JobInfo|ConnectorError closedJob = xmlUpdateOperator->closeJob();
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

        // Get batch information.
        BatchInfo|ConnectorError batchInfo = xmlUpdateOperator->getBatchInfo(batchIdUsingXml);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchIdUsingXml, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        // Get informations of all batches of this job.
        BatchInfo[]|ConnectorError allBatchInfo = xmlUpdateOperator->getAllBatches();
        if (allBatchInfo is BatchInfo[]) {
            test:assertTrue(allBatchInfo.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.detail()?.message.toString());
        }

        // Retrieve the json batch request.
        xml|ConnectorError batchRequest = xmlUpdateOperator->getBatchRequest(batchIdUsingXml);
        if (batchRequest is xml) {
            foreach var xmlBatch in batchRequest.*.elements() {
                if (xmlBatch is xml) {
                    test:assertTrue(xmlBatch[getElementNameWithNamespace("description")].getTextValue() == 
                        "Created_from_Ballerina_Sf_Bulk_API", 
                        msg = "Retrieving batch request failed.");                
                } else {
                    test:assertFail(msg = "Accessing xml batches from batch request failed, err=" 
                        + xmlBatch.toString());
                }
            }
        } else {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        }

        // Get the results of the batch
        Result[]|ConnectorError batchResult = xmlUpdateOperator->getResult(batchIdUsingXml, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(checkBatchResults(batchResult), msg = "Invalid batch result.");                
        } else {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        }

        // Abort job.
        JobInfo|ConnectorError abortedJob = xmlUpdateOperator->abortJob();
        if (abortedJob is JobInfo) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = xmlUpdateOperator.detail()?.message.toString());
    }
}
