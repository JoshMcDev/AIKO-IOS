#!/bin/bash

# Fix remaining closures in DocumentAnalysisFeature.swift

file="/Users/J/aiko/Sources/Features/DocumentAnalysisFeature.swift"

# Line 456 - updateAcquisitionTitle
sed -i '' '456s/return .run { send in/return .run { [acquisitionService = self.acquisitionService, acquisitionId] send in/' "$file"

# Line 471 - loadAcquisition
sed -i '' '471s/return .run { send in/return .run { [acquisitionService = self.acquisitionService, workflowEngine = self.workflowEngine] send in/' "$file"

# Line 518 - workflowStateChanged
sed -i '' '518s/return .run { send in/return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in/' "$file"

# Line 555 - processPromptResponse
sed -i '' '555s/return .run { send in/return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in/' "$file"

# Line 599 - approveWorkflowStep
sed -i '' '599s/return .run { send in/return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in/' "$file"

# Line 615 - refreshWorkflowContext
sed -i '' '615s/return .run { send in/return .run { [workflowEngine = self.workflowEngine, acquisitionId] send in/' "$file"

# Line 649 - createDocumentChain
sed -i '' '649s/return .run { send in/return .run { [documentChainManager = self.documentChainManager, acquisitionId] send in/' "$file"

# Line 666 - validateDocumentChain
sed -i '' '666s/return .run { send in/return .run { [documentChainManager = self.documentChainManager, acquisitionId] send in/' "$file"

# Line 685 - documentGeneratedInChain
sed -i '' '685s/return .run { send in/return .run { [documentChainManager = self.documentChainManager, workflowEngine = self.workflowEngine, acquisitionId, hasWorkflowContext] send in/' "$file"

echo "Fixed all remaining closures"