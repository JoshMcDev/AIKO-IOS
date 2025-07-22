/**
 * Webhook Server for AIKO Regulation Monitor
 * Receives push notifications about regulation updates
 */

import express from 'express';
import bodyParser from 'body-parser';
import { regulationMonitor } from './regulationUpdateMonitor';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

export class RegulationWebhookServer {
  private app: express.Application;
  private port: number;
  private webhookSecret: string;
  private receivedWebhooks: any[] = [];

  constructor(port: number = 3000) {
    this.port = port;
    this.app = express();
    this.webhookSecret = process.env.AIKO_WEBHOOK_SECRET || 'development-secret';
    this.setupMiddleware();
    this.setupRoutes();
  }

  private setupMiddleware(): void {
    // Parse JSON bodies
    this.app.use(bodyParser.json({
      verify: (req: any, res, buf) => {
        // Store raw body for signature verification
        req.rawBody = buf.toString('utf8');
      }
    }));

    // CORS for browser-based testing
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, X-Webhook-Signature');
      res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      next();
    });

    // Request logging
    this.app.use((req, res, next) => {
      console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
      next();
    });
  }

  private setupRoutes(): void {
    // Main webhook endpoint
    this.app.post('/webhook/regulation-update', async (req, res) => {
      console.log('Received regulation update webhook');
      
      try {
        // Validate webhook signature
        if (!this.validateWebhookSignature(req)) {
          console.warn('Invalid webhook signature');
          return res.status(401).json({ 
            error: 'Invalid signature',
            message: 'Webhook signature validation failed'
          });
        }

        // Log received webhook
        this.receivedWebhooks.push({
          timestamp: new Date(),
          payload: req.body,
          headers: req.headers
        });

        // Parse and validate payload
        const updates = this.parseWebhookPayload(req.body);
        
        if (!updates || updates.length === 0) {
          return res.status(400).json({ 
            error: 'Invalid payload format',
            message: 'No valid updates found in webhook payload'
          });
        }

        console.log(`Processing ${updates.length} regulation updates from webhook`);

        // Process updates
        const processedUpdates = [];
        for (const update of updates) {
          try {
            // Trigger monitor to check specific regulation
            console.log(`Checking ${update.regulation} for updates...`);
            
            // In production, this would trigger specific checks
            // For now, we'll simulate processing
            processedUpdates.push({
              ...update,
              processed: true,
              timestamp: new Date()
            });
            
            // Log the update
            this.logWebhookUpdate(update);
          } catch (error) {
            console.error(`Error processing update for ${update.regulation}:`, error);
          }
        }

        // Trigger full check after webhook
        if (processedUpdates.length > 0) {
          console.log('Triggering full regulation check after webhook...');
          // Don't await - let it run in background
          regulationMonitor.checkNow().catch(error => {
            console.error('Error in background check:', error);
          });
        }

        // Send success response
        res.status(200).json({ 
          status: 'success',
          message: `Processed ${processedUpdates.length} updates`,
          updates: processedUpdates,
          timestamp: new Date()
        });

      } catch (error: any) {
        console.error('Webhook processing error:', error);
        res.status(500).json({ 
          error: 'Internal server error',
          message: error.message
        });
      }
    });

    // Health check endpoint
    this.app.get('/health', (req, res) => {
      const health = {
        status: 'healthy',
        service: 'AIKO Regulation Monitor Webhook Server',
        timestamp: new Date(),
        uptime: process.uptime(),
        lastCheck: {
          FAR: regulationMonitor.getLastCheckTime('FAR'),
          DFARS: regulationMonitor.getLastCheckTime('DFARS'),
          'DFARS_PGI': regulationMonitor.getLastCheckTime('DFARS_PGI')
        },
        webhooksReceived: this.receivedWebhooks.length,
        lastWebhook: this.receivedWebhooks[this.receivedWebhooks.length - 1]?.timestamp
      };
      
      res.status(200).json(health);
    });

    // Webhook history endpoint
    this.app.get('/webhook/history', (req, res) => {
      const limit = parseInt(req.query.limit as string) || 10;
      const history = this.receivedWebhooks.slice(-limit).reverse();
      
      res.status(200).json({
        count: history.length,
        total: this.receivedWebhooks.length,
        webhooks: history
      });
    });

    // Test endpoint
    this.app.post('/webhook/test', (req, res) => {
      console.log('Test webhook received:', req.body);
      res.status(200).json({ 
        status: 'success',
        message: 'Test webhook received',
        echo: req.body
      });
    });

    // Root endpoint
    this.app.get('/', (req, res) => {
      res.json({
        service: 'AIKO Regulation Monitor Webhook Server',
        version: '1.0.0',
        endpoints: {
          webhook: '/webhook/regulation-update',
          health: '/health',
          history: '/webhook/history',
          test: '/webhook/test'
        },
        documentation: 'See README.md for webhook payload format'
      });
    });
  }

  private validateWebhookSignature(req: express.Request): boolean {
    // Get signature from headers
    const signature = req.headers['x-webhook-signature'] as string;
    
    if (!signature) {
      console.warn('No webhook signature provided');
      return false;
    }

    // In development, accept test signatures
    if (process.env.NODE_ENV === 'development' && signature === 'test-signature') {
      return true;
    }

    // Calculate expected signature
    const rawBody = (req as any).rawBody || JSON.stringify(req.body);
    const expectedSignature = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(rawBody)
      .digest('hex');

    // Compare signatures
    const isValid = crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );

    if (!isValid) {
      console.warn('Webhook signature mismatch');
    }

    return isValid;
  }

  private parseWebhookPayload(payload: any): any[] {
    const updates: any[] = [];

    // Handle single regulation update
    if (payload.regulation && payload.changes) {
      payload.changes.forEach((change: any) => {
        updates.push({
          regulation: payload.regulation,
          ...change,
          effectiveDate: new Date(change.effectiveDate)
        });
      });
    }

    // Handle multiple regulation updates
    if (payload.regulations && Array.isArray(payload.regulations)) {
      payload.regulations.forEach((reg: any) => {
        if (reg.regulation && reg.changes) {
          reg.changes.forEach((change: any) => {
            updates.push({
              regulation: reg.regulation,
              ...change,
              effectiveDate: new Date(change.effectiveDate)
            });
          });
        }
      });
    }

    // Handle legacy format (if any)
    if (payload.updates && Array.isArray(payload.updates)) {
      payload.updates.forEach((update: any) => {
        updates.push({
          ...update,
          effectiveDate: new Date(update.effectiveDate)
        });
      });
    }

    return updates;
  }

  private logWebhookUpdate(update: any): void {
    const logDir = path.join(__dirname, 'webhook-logs');
    fs.mkdirSync(logDir, { recursive: true });

    const logFile = path.join(logDir, `webhook-${new Date().toISOString().split('T')[0]}.log`);
    const logEntry = `[${new Date().toISOString()}] ${JSON.stringify(update)}\n`;
    
    fs.appendFileSync(logFile, logEntry);
  }

  start(): void {
    this.app.listen(this.port, () => {
      console.log('='.repeat(50));
      console.log('AIKO Regulation Monitor Webhook Server');
      console.log('='.repeat(50));
      console.log(`Server listening on port ${this.port}`);
      console.log(`Webhook endpoint: http://localhost:${this.port}/webhook/regulation-update`);
      console.log(`Health check: http://localhost:${this.port}/health`);
      console.log(`Webhook history: http://localhost:${this.port}/webhook/history`);
      console.log('='.repeat(50));
    });
  }

  stop(): void {
    console.log('Shutting down webhook server...');
    // In a real implementation, would properly close the server
  }
}

// CLI runner
if (require.main === module) {
  const server = new RegulationWebhookServer(
    parseInt(process.env.PORT || '3000')
  );
  
  server.start();

  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log('\nReceived SIGINT, shutting down gracefully...');
    server.stop();
    process.exit(0);
  });

  process.on('SIGTERM', () => {
    console.log('\nReceived SIGTERM, shutting down gracefully...');
    server.stop();
    process.exit(0);
  });
}

export default RegulationWebhookServer;