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

# Salesforce version.
# + label - label of the salesforce version
# + url - url of the salesforce version
# + versionNo - salesforce version number
public type Version record {
    string label;
    string url;
    string versionNo;
};

function getVersions(json|SalesforceError payload) returns Version[]|SalesforceError {
    Version[] versions = [];
    json[] versionsArr = <json[]> payload;

    foreach json ele in versionsArr {
        Version|error ver = {
            label: ele.label.toString(),
            url: ele.url.toString(),
            versionNo: ele.'version.toString()
        };

        if (ver is Version) {
            versions[versions.length()] = ver;
        } else {
            log:printError("Creating versions array failed", err = ver);
            return getSalesforceError("Creating versions array failed", http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
    return versions;
}