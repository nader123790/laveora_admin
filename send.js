import axios from "axios";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    const { title, message } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: "title and message are required" });
    }

    const ONE_SIGNAL_APP_ID = "80e9a120-0f85-4238-add0-92fa66c3a40c";
    const ONE_SIGNAL_REST_API_KEY =
      "PUT_YOUR_REST_API_KEY_HERE";

    const response = await axios.post(
      "https://onesignal.com/api/v1/notifications",
      {
        app_id: ONE_SIGNAL_APP_ID,
        included_segments: ["All"],
        headings: { en: title, ar: title },
        contents: { en: message, ar: message },
      },
      {
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Basic ${ONE_SIGNAL_REST_API_KEY}`,
        },
      }
    );

    return res.status(200).json({ success: true, onesignal: response.data });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.response?.data || error.message,
    });
  }
}