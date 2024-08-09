package main

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"sync"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// listenPosts listens for new posts and checks for mentions in the content.
func listenPosts(ctx context.Context, client *firestore.Client, fcmClient *messaging.Client, wg *sync.WaitGroup) {
	defer wg.Done()

	it := client.Collection("posts").Snapshots(ctx)
	isInitialSnapshot := true

	for {
		snap, err := it.Next()
		if status.Code(err) == codes.DeadlineExceeded {
			return
		}
		if err != nil {
			log.Printf("Snapshots.Next error for collection posts: %v\n", err)
			return
		}

		if isInitialSnapshot {
			isInitialSnapshot = false
			continue
		}

		for _, change := range snap.Changes {
			if change.Kind == firestore.DocumentAdded {
				doc := change.Doc
				content := doc.Data()["content"].(string)
				senderId := doc.Data()["userId"].(string)

				// Fetch the sender's username
				senderSnap, err := client.Collection("users").Doc(senderId).Get(ctx)
				if err != nil {
					log.Printf("Error fetching user %s: %v\n", senderId, err)
					continue
				}
				senderUsername := senderSnap.Data()["username"].(string)

				// Mentions detection
				mentionedUsers := extractMentions(content)

				for _, username := range mentionedUsers {
					// Check if the mentioned user exists
					userSnap, err := client.Collection("users").Where("username", "==", username).Limit(1).Documents(ctx).Next()
					if err != nil {
						log.Printf("Error fetching user %s: %v\n", username, err)
						continue
					}
					if userSnap != nil {
						deviceTokens := userSnap.Data()["deviceTokens"].([]interface{})
						var tokens []string
						for _, token := range deviceTokens {
							tokens = append(tokens, token.(string))
						}

						messageBody := fmt.Sprintf("New Mention from %s: %s", senderUsername, content)
						err = sendFCMNotification(ctx, fcmClient, "New Mention", messageBody, tokens)
						if err != nil {
							log.Printf("Failed to send FCM notification for user %s: %v\n", username, err)
						}
					}
				}
			}
		}
	}
}

// listenFollows listens for new follow relationships and sends notifications.
func listenFollows(ctx context.Context, client *firestore.Client, fcmClient *messaging.Client, wg *sync.WaitGroup) {
	defer wg.Done()

	it := client.Collection("follows").Snapshots(ctx)
	isInitialSnapshot := true

	for {
		snap, err := it.Next()
		if status.Code(err) == codes.DeadlineExceeded {
			return
		}
		if err != nil {
			log.Printf("Snapshots.Next error for collection follow: %v\n", err)
			return
		}

		if isInitialSnapshot {
			isInitialSnapshot = false
			continue
		}

		for _, change := range snap.Changes {
			if change.Kind == firestore.DocumentAdded {
				doc := change.Doc
				followingId := doc.Data()["followingId"].(string)
				followerId := doc.Data()["followerId"].(string)

				// Fetch the follower's username
				followerSnap, err := client.Collection("users").Doc(followerId).Get(ctx)
				if err != nil {
					log.Printf("Error fetching follower %s: %v\n", followerId, err)
					continue
				}
				followerUsername := followerSnap.Data()["username"].(string)

				// Fetch the user to notify (followingId)
				userSnap, err := client.Collection("users").Doc(followingId).Get(ctx)
				if err != nil {
					log.Printf("Error fetching user %s: %v\n", followingId, err)
					continue
				}

				if userSnap != nil {
					deviceTokens := userSnap.Data()["deviceTokens"].([]interface{})
					var tokens []string
					for _, token := range deviceTokens {
						tokens = append(tokens, token.(string))
					}

					messageBody := fmt.Sprintf("You have a new follower: %s", followerUsername)
					err = sendFCMNotification(ctx, fcmClient, "New Follower", messageBody, tokens)
					if err != nil {
						log.Printf("Failed to send FCM notification for user %s: %v\n", followingId, err)
					}
				}
			}
		}
	}
}

// extractMentions extracts mentions from the content string.
func extractMentions(content string) []string {
	re := regexp.MustCompile(`@(\w+)`)
	matches := re.FindAllStringSubmatch(content, -1)

	var mentions []string
	for _, match := range matches {
		mentions = append(mentions, match[1])
	}

	return mentions
}

// sendFCMNotification sends a multicast FCM notification to a list of registration tokens.
func sendFCMNotification(ctx context.Context, fcmClient *messaging.Client, title, body string, registrationTokens []string) error {
	message := &messaging.MulticastMessage{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Tokens: registrationTokens,
	}

	br, err := fcmClient.SendMulticast(ctx, message)
	if err != nil {
		return fmt.Errorf("error sending FCM multicast message: %w", err)
	}

	fmt.Printf("%d messages were sent successfully\n", br.SuccessCount)
	return nil
}

func main() {
	projectID := "outliner-f560b"
	ctx := context.Background()

	opt := option.WithCredentialsFile("C:\\Users\\Iris\\Documents\\outliner-f560b-firebase-adminsdk-wl4kg-7cef99f07d.json")

	conf := &firebase.Config{ProjectID: projectID}
	app, err := firebase.NewApp(ctx, conf, opt)
	if err != nil {
		log.Fatalf("error initializing firebase app: %v\n", err)
	}

	client, err := firestore.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("Error creating Firestore client: %v\n", err)
	}
	defer client.Close()

	fcmClient, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("error creating FCM client: %v\n", err)
	}

	fmt.Println("Firestore client and FCM client successfully created. Listening for changes...")

	var wg sync.WaitGroup

	wg.Add(2)
	go listenPosts(ctx, client, fcmClient, &wg)
	go listenFollows(ctx, client, fcmClient, &wg)

	wg.Wait()
}
