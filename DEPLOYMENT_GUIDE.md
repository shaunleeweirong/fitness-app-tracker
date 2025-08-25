# 🚀 ExerciseDB Free Deployment Guide

## Overview
Deploy your own **FREE** ExerciseDB API with 5,000+ exercises to Vercel - no monthly costs, no API keys, no rate limits!

---

## Step 1: Deploy ExerciseDB to Vercel (5 minutes)

### Option A: One-Click Deployment
1. **Go to**: [ExerciseDB GitHub Repository](https://github.com/exercisedb/exercisedb-api)
2. **Click**: The "Deploy with Vercel" button (purple button in README)
3. **Login**: Connect your GitHub account to Vercel
4. **Deploy**: Click "Deploy" - Vercel will automatically build and host your API
5. **Get URL**: Copy your deployment URL (e.g., `https://exercisedb-api-[your-username].vercel.app`)

### Option B: Manual Fork & Deploy
1. **Fork** the repository to your GitHub account
2. **Login** to [Vercel Dashboard](https://vercel.com/dashboard)
3. **Import** your forked repository
4. **Deploy** with default settings
5. **Get URL** from your Vercel dashboard

---

## Step 2: Update Flutter App Configuration (2 minutes)

Once you have your Vercel URL, update the Flutter app:

1. **Open**: `lib/services/exercise_api_client.dart`
2. **Replace** line 12:
   ```dart
   // Change this line:
   static const String _selfHostedUrl = 'https://your-exercisedb.vercel.app';
   
   // To your actual Vercel URL:
   static const String _selfHostedUrl = 'https://exercisedb-api-[your-username].vercel.app';
   ```

3. **Save** and restart your Flutter app

---

## Step 3: Verify Deployment (1 minute)

Test your API endpoints (use the correct `/api/v1/` prefix):

### Basic Exercise List
```
GET https://your-vercel-url.vercel.app/api/v1/exercises?limit=5&offset=0
```

### Exercises by Body Part
```
GET https://your-vercel-url.vercel.app/api/v1/bodyparts/chest/exercises?limit=10
```

### Body Parts List
```
GET https://your-vercel-url.vercel.app/api/v1/bodyparts
```

### Equipment List
```
GET https://your-vercel-url.vercel.app/api/v1/equipments
```

### Search Exercises
```
GET https://your-vercel-url.vercel.app/api/v1/exercises/search?q=push&limit=10
```

### Expected Response Format
All endpoints return data in this wrapper format:
```json
{
  "success": true,
  "metadata": {
    "totalPages": 75,
    "totalExercises": 1500,
    "currentPage": 1,
    "previousPage": null,
    "nextPage": "..."
  },
  "data": [
    // Array of exercises or body parts/equipment
  ]
}
```

---

## 🎉 Expected Results

After deployment, your app will have:

### ✅ **Free Benefits**
- **5,000+ exercises** from full ExerciseDB dataset
- **No monthly costs** (vs $10-500/month for RapidAPI)
- **No rate limits** or API key management
- **Better performance** (dedicated instance)
- **Full control** over API and data

### ✅ **Rich Exercise Data**
Each exercise includes:
- Exercise name and ID
- Target muscle groups (primary + secondary)
- Equipment requirements
- Step-by-step instructions
- Exercise tips and variations
- Related exercises
- Images and videos
- Keywords and overview

### ✅ **API Endpoints Available**
- `/api/v1/exercises` - All exercises with pagination
- `/api/v1/exercises/search` - Fuzzy search with configurable threshold
- `/api/v1/exercises/filter` - Advanced filtering by multiple criteria
- `/api/v1/exercises/{exerciseId}` - Get specific exercise by ID
- `/api/v1/bodyparts` - Available body parts list
- `/api/v1/bodyparts/{bodyPart}/exercises` - Exercises filtered by body part
- `/api/v1/equipments` - Available equipment types list
- `/api/v1/equipments/{equipment}/exercises` - Exercises filtered by equipment
- `/api/v1/muscles` - Available muscle groups list

**All endpoints support:**
- Pagination (`limit`, `offset` parameters)
- Sorting (`sortBy`, `sortOrder` parameters)
- Consistent response wrapper with metadata

---

## 🔧 Troubleshooting

### Issue: "Network Error" or "API not responding"
**Solution**: 
1. Check your Vercel deployment status in dashboard
2. Verify the URL is correct in `exercise_api_client.dart`
3. Test API endpoint directly in browser

### Issue: "No exercises loading" or "Failed to load exercises"
**Solution**:
1. Ensure `useSelfHosted: true` in ExerciseService
2. **RESTART Flutter app completely** after URL change
3. Check Flutter console for error messages
4. **iOS Simulator Issue**: If still not working, **completely quit and restart the iOS Simulator**:
   ```bash
   # Kill simulator
   killall "Simulator"
   
   # Clean Flutter cache
   flutter clean
   flutter pub get
   
   # Restart simulator and app
   open -a Simulator
   flutter run --debug
   ```

### Issue: "Type 'Null' is not a subtype of type 'String'" errors
**Solution**:
1. **Restart the iOS Simulator completely** (most common fix)
2. Run `flutter clean` and `flutter pub get`
3. Regenerate JSON serialization: `flutter packages pub run build_runner build --delete-conflicting-outputs`
4. If persists, delete app from simulator and reinstall

### Issue: App shows mock data instead of real API data
**Solution**:
1. **Primary fix**: Completely restart iOS Simulator (kills cached states)
2. Verify API URL is correct in console logs
3. Check Vercel logs to ensure API calls are reaching your deployment
4. Clear app cache and restart

### Issue: "Deployment failed"
**Solution**:
1. Try manual fork & deploy method
2. Check Vercel build logs for errors
3. Contact ExerciseDB support: support@exercisedb.dev

### 🚨 **Most Common Issue: iOS Simulator Caching**
**Symptoms**: API integration works in logs but app still shows "No exercises" or mock data
**Root Cause**: iOS Simulator can cache old app states and network configurations
**Solution**: **Complete simulator restart** (see steps above) - this fixes 90% of integration issues!

---

## 💡 Pro Tips

1. **Custom Domain** (Optional): Add your own domain in Vercel settings for branding
2. **Caching**: Your deployment automatically includes caching for better performance
3. **Scaling**: Vercel automatically scales based on usage
4. **Updates**: Redeploy from GitHub to get latest exercise data
5. **Monitoring**: Use Vercel Analytics to monitor API usage

---

## 📊 Cost Comparison

| Solution | Setup Cost | Monthly Cost | Rate Limits | Data Control |
|----------|------------|--------------|-------------|--------------|
| **Self-Hosted (Recommended)** | **FREE** | **FREE** | **None** | **Full** |
| RapidAPI Basic | $0 | $10-50 | Yes | Limited |
| RapidAPI Pro | $0 | $100-500 | Higher | Limited |
| Custom Database | $50-200 | $5-20 | None | Full |

**Winner**: Self-hosted Vercel deployment - **$0 total cost**!

---

## 🚀 Next Steps

After deployment:
1. ✅ Test API endpoints work
2. ✅ Update Flutter app URL configuration  
3. ✅ Verify exercise data loads in app
4. 🔄 Add body part visualization
5. 🔄 Enhance exercise display with images
6. 🔄 Implement advanced filtering

---

## 📞 Support

- **ExerciseDB Support**: support@exercisedb.dev
- **Vercel Support**: [Vercel Documentation](https://vercel.com/docs)
- **Flutter Issues**: Check console logs and error messages

Ready to deploy? Follow Step 1 above and get your free API running in 5 minutes! 🎯