/**
 * Test script for AIKO Regulation Update Monitor Webhook
 * Simulates webhook notifications from acquisition.gov
 */

import axios from 'axios';

// Test webhook payloads
const testPayloads = {
  // FAR update example
  farUpdate: {
    regulation: "FAR",
    changes: [
      {
        clauseNumber: "52.217-8",
        changeType: "modified",
        effectiveDate: "2025-01-15",
        federalRegisterCitation: "90 FR 12345",
        description: "Option to Extend Services - Updated language for service contract extensions"
      },
      {
        clauseNumber: "52.232-40",
        changeType: "added",
        effectiveDate: "2025-01-15",
        federalRegisterCitation: "90 FR 12346",
        description: "New clause for electronic payment processing requirements"
      }
    ]
  },

  // DFARS update example
  dfarsUpdate: {
    regulation: "DFARS",
    changes: [
      {
        clauseNumber: "252.225-7001",
        changeType: "modified",
        effectiveDate: "2025-01-20",
        federalRegisterCitation: "90 FR 23456",
        description: "Buy American Act updates for critical supplies"
      },
      {
        clauseNumber: "252.204-7020",
        changeType: "deleted",
        effectiveDate: "2025-01-20",
        federalRegisterCitation: "90 FR 23457",
        description: "Obsolete cybersecurity clause replaced by CMMC requirements"
      }
    ]
  },

  // Multiple regulation update
  multiUpdate: {
    regulations: [
      {
        regulation: "FAR",
        changes: [
          {
            clauseNumber: "52.219-9",
            changeType: "modified",
            effectiveDate: "2025-02-01",
            federalRegisterCitation: "90 FR 34567"
          }
        ]
      },
      {
        regulation: "DFARS",
        changes: [
          {
            clauseNumber: "252.211-7003",
            changeType: "modified",
            effectiveDate: "2025-02-01",
            federalRegisterCitation: "90 FR 34568"
          }
        ]
      }
    ]
  }
};

// Test functions
async function testWebhookEndpoint(payload: any, endpoint: string = 'http://localhost:3000/webhook/regulation-update') {
  try {
    console.log(`\nTesting webhook with payload:`, JSON.stringify(payload, null, 2));
    
    const response = await axios.post(endpoint, payload, {
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Source': 'acquisition.gov', // Simulated header
        'X-Webhook-Signature': 'test-signature' // Would be real HMAC in production
      }
    });

    console.log('Response status:', response.status);
    console.log('Response data:', response.data);
    return response;
  } catch (error: any) {
    console.error('Webhook test failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

// Health check
async function checkHealth(endpoint: string = 'http://localhost:3000/health') {
  try {
    const response = await axios.get(endpoint);
    console.log('Health check response:', response.data);
    return response.data;
  } catch (error: any) {
    console.error('Health check failed:', error.message);
    throw error;
  }
}

// Manual trigger for immediate check
async function triggerManualCheck() {
  try {
    console.log('\nTriggering manual regulation check...');
    
    // This would call the CLI directly
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);
    
    const { stdout, stderr } = await execAsync('npm run check', {
      cwd: '/Users/J/aiko/Sources/Resources/Regulations/UpdateMonitor'
    });
    
    console.log('Check output:', stdout);
    if (stderr) console.error('Check errors:', stderr);
  } catch (error) {
    console.error('Manual check failed:', error);
  }
}

// Main test runner
async function runTests() {
  console.log('='.repeat(50));
  console.log('AIKO Regulation Monitor Webhook Tests');
  console.log('='.repeat(50));

  try {
    // 1. Check if webhook server is running
    console.log('\n1. Checking webhook server health...');
    await checkHealth();

    // 2. Test FAR update webhook
    console.log('\n2. Testing FAR update webhook...');
    await testWebhookEndpoint(testPayloads.farUpdate);

    // 3. Test DFARS update webhook
    console.log('\n3. Testing DFARS update webhook...');
    await testWebhookEndpoint(testPayloads.dfarsUpdate);

    // 4. Test multi-regulation update
    console.log('\n4. Testing multi-regulation update webhook...');
    await testWebhookEndpoint(testPayloads.multiUpdate);

    // 5. Test invalid payload
    console.log('\n5. Testing invalid payload handling...');
    try {
      await testWebhookEndpoint({ invalid: "payload" });
    } catch (error) {
      console.log('Invalid payload correctly rejected');
    }

    // 6. Trigger manual check
    console.log('\n6. Triggering manual regulation check...');
    await triggerManualCheck();

    console.log('\n' + '='.repeat(50));
    console.log('All tests completed successfully!');
    console.log('='.repeat(50));

  } catch (error) {
    console.error('\nTest suite failed:', error);
    process.exit(1);
  }
}

// CLI interface
import { Command } from 'commander';

const program = new Command();

program
  .name('test-webhook')
  .description('Test AIKO Regulation Monitor webhook endpoints')
  .version('1.0.0');

program
  .command('far')
  .description('Test FAR update webhook')
  .action(async () => {
    await testWebhookEndpoint(testPayloads.farUpdate);
  });

program
  .command('dfars')
  .description('Test DFARS update webhook')
  .action(async () => {
    await testWebhookEndpoint(testPayloads.dfarsUpdate);
  });

program
  .command('multi')
  .description('Test multi-regulation update webhook')
  .action(async () => {
    await testWebhookEndpoint(testPayloads.multiUpdate);
  });

program
  .command('health')
  .description('Check webhook server health')
  .action(async () => {
    await checkHealth();
  });

program
  .command('all')
  .description('Run all tests')
  .action(async () => {
    await runTests();
  });

program
  .command('manual')
  .description('Trigger manual regulation check')
  .action(async () => {
    await triggerManualCheck();
  });

// Custom payload option
program
  .command('custom')
  .description('Send custom webhook payload')
  .requiredOption('-p, --payload <json>', 'JSON payload to send')
  .option('-e, --endpoint <url>', 'Webhook endpoint URL', 'http://localhost:3000/webhook/regulation-update')
  .action(async (options) => {
    try {
      const payload = JSON.parse(options.payload);
      await testWebhookEndpoint(payload, options.endpoint);
    } catch (error: any) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  });

// Parse command line arguments
if (require.main === module) {
  program.parse(process.argv);
}

// Export for use in other scripts
export { testWebhookEndpoint, checkHealth, triggerManualCheck, testPayloads };