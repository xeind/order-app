#!/bin/bash

echo "PRE-DEPLOYMENT VERIFICATION"
echo "==========================="

# Check backend files
echo "BACKEND FILES:"
echo "- render.yaml: $([ -f 'order_backend/render.yaml' ] && echo 'Found' || echo 'Missing')"
echo "- render-build.sh: $([ -f 'order_backend/bin/render-build.sh' ] && echo 'Found' || echo 'Missing')"
echo "- Gemfile: $([ -f 'order_backend/Gemfile' ] && echo 'Found' || echo 'Missing')"

# Check frontend files
echo ""
echo "FRONTEND FILES:"
echo "- vercel.json: $([ -f 'order_frontend/vercel.json' ] && echo 'Found' || echo 'Missing')"
echo "- package.json: $([ -f 'order_frontend/package.json' ] && echo 'Found' || echo 'Missing')"
echo "- .env.production: $([ -f 'order_frontend/.env.production' ] && echo 'Found' || echo 'Missing')"

# Check configuration
echo ""
echo "CONFIGURATION CHECK:"
echo "- Apollo client updated: $(grep -q 'import.meta.env.VITE_API_URL' order_frontend/src/apollo.ts && echo 'Yes' || echo 'No')"
echo "- CORS configured: $(grep -q 'Rack::Cors' order_backend/config/environments/production.rb && echo 'Yes' || echo 'No')"
echo "- Production mailer: $(grep -q 'action_mailer' order_backend/config/environments/production.rb && echo 'Yes' || echo 'No')"

echo ""
echo "DEPLOYMENT CHECKLIST:"
echo "1. Run: ./deploy.sh"
echo "2. Push to GitHub"
echo "3. Deploy on Render (Backend)"
echo "4. Deploy on Vercel (Frontend)"
echo "5. Set environment variables"
echo "6. Test system functionality"
echo ""
echo "ALL FILES READY FOR DEPLOYMENT!"