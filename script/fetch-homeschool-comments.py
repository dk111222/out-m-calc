import praw
import csv

# ========== 在这里填入你的Reddit密钥 ==========
CLIENT_ID = "xxx"
CLIENT_SECRET = "xxx"
USER_AGENT = "math-drill-scraper/0.1 by xxx"
# ============================================

SEARCH_KEYWORDS = [
    "homeschool math fact app frustrations",
    "multiplication flashcard app complaints",
    "math drill app too many ads",
    "math app cannot turn off timer",
    "homeschool math app printable worksheet"
]
SUBREDDITS = ["homeschool", "homeschooling"]
OUTPUT_CSV = "reddit_homeschool_comments.csv"

reddit = praw.Reddit(
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    user_agent=USER_AGENT
)

rows = []
for sub_name in SUBREDDITS:
    sub = reddit.subreddit(sub_name)
    for kw in SEARCH_KEYWORDS:
        print(f"Search r/{sub_name} : {kw}")
        for submission in sub.search(kw, limit=20):
            # 帖子本身
            rows.append({
                "source": f"r/{sub_name}",
                "type": "post",
                "title": submission.title,
                "text": submission.selftext,
                "score": submission.score
            })
            # 评论
            submission.comments.replace_more(limit=0)
            for c in submission.comments.list():
                if hasattr(c, "body"):
                    rows.append({
                        "source": f"r/{sub_name}",
                        "type": "comment",
                        "title": "",
                        "text": c.body,
                        "score": c.score
                    })

with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["source","type","title","text","score"])
    w.writeheader()
    w.writerows(rows)
print(f"Reddit scrape done, total {len(rows)} items")
