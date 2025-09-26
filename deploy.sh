#!/bin/bash
echo "ULTRA-FAST DEPLOYMENT SCRIPT"
echo "============================="

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git branch -M main
fi

# Add and commit all files
echo "Adding files to Git..."
git add .
git status

echo "Committing changes..."
read -p "Enter commit message (or press Enter for default): " commit_msg
if [ -z "$commit_msg" ]; then
    commit_msg="Deploy: Goshomo POS - Rails backend + Vue frontend with order management"
fi

git commit -m "$commit_msg"

echo "NEXT STEPS:"
echo ""
echo "1. Push to GitHub:"
echo "   git remote add origin https://github.com/yourusername/goshomo.git"
echo "   git push -u origin main"
echo ""
echo "2. RENDER (Backend):"
echo "   - Go to https://render.com"
echo "   - New Web Service → Connect repo"
echo "   - Root Directory: order_backend"
echo "   - Build: ./bin/render-build.sh"
echo "   - Start: bundle exec puma -C config/puma.rb"
echo ""
echo "3. VERCEL (Frontend):"
echo "   - Go to https://vercel.com"
echo "   - Import repo → Root Directory: order_frontend"
echo "   - Framework: Vue.js"
echo ""
echo "4. Set Environment Variables:"
echo "   RENDER: RAILS_MASTER_KEY, DATABASE_URL"
echo "   VERCEL: VITE_API_URL=https://your-app.onrender.com/graphql"
echo ""
echo "Ready for deployment!"