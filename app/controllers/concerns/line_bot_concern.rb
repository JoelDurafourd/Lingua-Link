require 'line/bot'
require "google/cloud/translate/v2"

class LineMessageTemplates
  def self.res_card
    return {
      type: 'flex',
      altText: 'Teacher Profile',
      contents: {
        type: "bubble",
        size: "giga",
        direction: "ltr",
        header: {
          type: "box",
          layout: "vertical",
          spacing: "none",
          margin: "none",
          paddingAll: "0px",
          backgroundColor: "#FFFFFFFF",
          contents: [
            {
              type: "box",
              layout: "horizontal",
              offsetTop: "5px",
              contents: [
                {
                  type: "text",
                  text: "Reservation System",
                  weight: "bold",
                  align: "center",
                  gravity: "center",
                  contents: []
                }
              ]
            },
            {
              type: "separator",
              margin: "md"
            },
            {
              type: "box",
              layout: "vertical",
              offsetTop: "5px",
              contents: [
                {
                  type: "text",
                  text: "Ms. Jane Smith",
                  weight: "bold",
                  size: "xl",
                  align: "center",
                  gravity: "center",
                  contents: []
                },
                {
                  type: "box",
                  layout: "horizontal",
                  spacing: "xl",
                  paddingTop: "10px",
                  paddingBottom: "20px",
                  paddingStart: "20px",
                  paddingEnd: "20px",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      width: "72px",
                      height: "72px",
                      cornerRadius: "100px",
                      contents: [
                        {
                          type: "image",
                          url: "https://avatar.iran.liara.run/public",
                          size: "full"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      contents: [
                        {
                          type: "box",
                          layout: "baseline",
                          contents: [
                            {
                              type: "icon",
                              url: "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                            },
                            {
                              type: "text",
                              text: "Mathematics",
                              contents: []
                            }
                          ]
                        },
                        {
                          type: "box",
                          layout: "baseline",
                          contents: [
                            {
                              type: "icon",
                              url: "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                            },
                            {
                              type: "text",
                              text: "AP Certified",
                              contents: []
                            }
                          ]
                        },
                        {
                          type: "box",
                          layout: "baseline",
                          contents: [
                            {
                              type: "icon",
                              url: "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                            },
                            {
                              type: "text",
                              text: "10+ yrs",
                              contents: []
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        body: {
          type: "box",
          layout: "vertical",
          contents: [
            {
              type: "box",
              layout: "vertical",
              contents: [
                {
                  type: "box",
                  layout: "horizontal",
                  spacing: "none",
                  margin: "none",
                  contents: [
                    {
                      type: "text",
                      text: "SUN",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "MON",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "TUE",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "WED",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "THU",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "FRI",
                      weight: "bold",
                      align: "center",
                      contents: []
                    },
                    {
                      type: "text",
                      text: "SAT",
                      weight: "bold",
                      align: "center",
                      contents: []
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "horizontal",
                  height: "90px",
                  borderColor: "#000000FF",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      borderColor: "#000000FF",
                      cornerRadius: "5px",
                      contents: [
                        {
                          type: "text",
                          text: "3/1",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/2",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/3",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/4",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/5",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/6",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/7",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "horizontal",
                  height: "90px",
                  borderColor: "#000000FF",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      borderColor: "#000000FF",
                      cornerRadius: "5px",
                      contents: [
                        {
                          type: "text",
                          text: "3/8",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/9",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/10",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/11",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/12",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/13",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/14",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "horizontal",
                  height: "90px",
                  borderColor: "#000000FF",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      borderColor: "#000000FF",
                      cornerRadius: "5px",
                      contents: [
                        {
                          type: "text",
                          text: "3/15",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/16",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/17",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/18",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/19",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/20",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/21",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "horizontal",
                  height: "90px",
                  borderColor: "#000000FF",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      borderColor: "#000000FF",
                      cornerRadius: "5px",
                      contents: [
                        {
                          type: "text",
                          text: "3/22",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/23",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/24",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/25",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/26",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/27",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/28",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "horizontal",
                  height: "90px",
                  borderColor: "#000000FF",
                  contents: [
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      borderColor: "#000000FF",
                      cornerRadius: "5px",
                      contents: [
                        {
                          type: "text",
                          text: "3/29",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035769.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/30",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "box",
                      layout: "vertical",
                      flex: 1,
                      position: "relative",
                      contents: [
                        {
                          type: "text",
                          text: "3/31",
                          align: "center",
                          offsetTop: "5px",
                          contents: []
                        },
                        {
                          type: "separator",
                          margin: "sm"
                        },
                        {
                          type: "image",
                          url: "https://cdn-icons-png.flaticon.com/512/14035/14035711.png",
                          size: "xs"
                        }
                      ]
                    },
                    {
                      type: "filler"
                    },
                    {
                      type: "filler"
                    },
                    {
                      type: "filler"
                    },
                    {
                      type: "filler"
                    }
                  ]
                }
              ]
            }
          ]
        },
        footer: {
          type: "box",
          layout: "vertical",
          contents: [
            {
              type: "box",
              layout: "horizontal",
              contents: [
                {
                  type: "button",
                  action: {
                    type: "datetimepicker",
                    label: "Schedule",
                    data: "d",
                    mode: "date",
                    initial: "2024-08-13",
                    max: "2025-08-13",
                    min: "2023-08-13"
                  },
                  style: "primary"
                }
              ]
            },
            {
              type: "filler"
            }
          ]
        },
        styles: {
          footer: {
            backgroundColor: "#000000FF"
          }
        }
      }
    }
  end

  def self.teacher_card
    return {
      type: 'flex',
      altText: 'Teacher Profile',
      contents: {
        type: "bubble",
        hero: {
          type: "image",
          url: "https://via.placeholder.com/800x520?text=Teacher+Profile+Image",
          size: "full",
          aspectRatio: "20:13",
          aspectMode: "cover",
          action: {
            type: "uri",
            label: "View Full Profile",
            uri: "https://example.com/teacher-profile"
          }
        },
        body: {
          type: "box",
          layout: "vertical",
          contents: [
            {
              type: "text",
              text: "Ms. Jane Smith",
              weight: "bold",
              size: "xl",
              contents: []
            },
            {
              type: "box",
              layout: "baseline",
              margin: "md",
              contents: [
                {
                  type: "icon",
                  url: "https://via.placeholder.com/28x28?text=★",
                  size: "sm"
                },
                {
                  type: "icon",
                  url: "https://via.placeholder.com/28x28?text=★",
                  size: "sm"
                },
                {
                  type: "icon",
                  url: "https://via.placeholder.com/28x28?text=★",
                  size: "sm"
                },
                {
                  type: "icon",
                  url: "https://via.placeholder.com/28x28?text=☆",
                  size: "sm"
                },
                {
                  type: "icon",
                  url: "https://via.placeholder.com/28x28?text=★",
                  size: "sm"
                },
                {
                  type: "text",
                  text: "4.0",
                  size: "sm",
                  color: "#999999",
                  flex: 0,
                  margin: "md",
                  contents: []
                }
              ]
            },
            {
              type: "box",
              layout: "vertical",
              spacing: "sm",
              margin: "lg",
              contents: [
                {
                  type: "box",
                  layout: "baseline",
                  spacing: "sm",
                  contents: [
                    {
                      type: "text",
                      text: "📚",
                      size: "sm",
                      color: "#AAAAAA",
                      flex: 1,
                      contents: []
                    },
                    {
                      type: "text",
                      text: "Mathematics",
                      size: "sm",
                      color: "#666666",
                      flex: 5,
                      wrap: true,
                      contents: []
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "baseline",
                  spacing: "sm",
                  contents: [
                    {
                      type: "text",
                      text: "🎓",
                      size: "sm",
                      color: "#AAAAAA",
                      flex: 1,
                      contents: []
                    },
                    {
                      type: "text",
                      text: "10+ years",
                      size: "sm",
                      color: "#666666",
                      flex: 5,
                      wrap: true,
                      contents: []
                    }
                  ]
                },
                {
                  type: "box",
                  layout: "baseline",
                  spacing: "sm",
                  contents: [
                    {
                      type: "text",
                      text: "🏆",
                      size: "sm",
                      color: "#AAAAAA",
                      flex: 1,
                      contents: []
                    },
                    {
                      type: "text",
                      text: "AP Certified",
                      size: "sm",
                      color: "#666666",
                      flex: 5,
                      wrap: true,
                      contents: []
                    }
                  ]
                }
              ]
            }
          ]
        },
        footer: {
          type: "box",
          layout: "vertical",
          flex: 0,
          spacing: "sm",
          contents: [
            {
              type: "spacer"
            },
            {
              type: "button",
              action: {
                type: "datetimepicker",
                label: "Schedule Class",
                data: "1",
                mode: "datetime",
                initial: "2024-08-11T12:50",
                max: "2025-08-11T12:50",
                min: "2023-08-11T12:50"
              },
              color: "#1DB446",
              style: "primary"
            },
            {
              type: "button",
              action: {
                type: "uri",
                label: "View Full Profile",
                uri: "https://example.com/teacher-profile"
              }
            }
          ]
        }
      }
    }
  end
end

module LineBotConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client
  end

  # @param [Array<Line::Bot::Event::Class>] events
  def process_events(events)
    # rubocop:disable Metrics/MethodLength
    Rails.logger.info "Processing #{events.size} LINE events"

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        handle_message(event)
      when Line::Bot::Event::Postback
        handle_postback(event)
      when Line::Bot::Event::Follow
        handle_follow(event)
      else
        Rails.logger.warn "Unhandled event type: #{event}"
      end
    end
  end

  # @param [Line::Bot::Event::Message] event
  # def handle_message(event)
  #   log_event(event)
  #   user_id = event['source']['userId']
  #   text = event['message']['text']
  #   # case event.type
  #   # when Line::Bot::Event::MessageType::Text
  #   # else
  #   #   # type code here
  #   # end
  #
  #   Rails.logger.debug "Message content: #{text}"
  #
  #   begin
  #     # message = MessageTemplates.build_teacher_profile(
  #     #   name: "Ms. Jane Smith",
  #     #   rating: 4.0,
  #     #   subject: "Mathematics",
  #     #   experience: "10+ years",
  #     #   certification: "AP Certified",
  #     #   image_url: "https://example.com/teacher_image.jpg",
  #     #   profile_url: "https://example.com/teacher_profile"
  #     # )
  #
  #     # message = LineMessageTemplates.res_card
  #
  #     response = @line_service.reply_message(event['replyToken'], message)
  #
  #     raise "Bad response received: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)
  #
  #     Rails.logger.info "Reply message sent successfully for user #{user_id} with response #{response}"
  #   rescue StandardError => e
  #     Rails.logger.error "Error sending reply message: #{e.message}"
  #   end
  # end
  #

  def push_teacher_message(event) end

  def handle_message(event)
    Rails.logger.info "Handling message event: #{event.inspect}"

    message_data = event['message']
    source_data = event['source']

    line_user_id = source_data['userId']
    message_text = message_data['text']

    # Initialize your state machine service
    menu_manager = MenuManagerService.new
    current_state = menu_manager.get_or_create_state(line_user_id)

    # Handle the message based on the user's current state

    if current_state.name == 'teacher_direct_chat_menu_state'
      response_text = current_state.handle_input(message_text, event)

      if response_text[:in_chat]
        if message_text == '#2'
          reply_message = { type: 'text', text: response_text[:content] }

          # Send the reply
          reply_token = event['replyToken']
          @line_service.reply_message(reply_token, reply_message)
        end
      else
        reply_message = { type: 'text', text: response_text[:content] }

        # Send the reply
        reply_token = event['replyToken']
        @line_service.reply_message(reply_token, reply_message)
      end
    else
      response_text = current_state.handle_input(message_text)
      # Prepare the reply message (ensure response_text is a string)
      reply_message = { type: 'text', text: response_text }

      # Send the reply
      reply_token = event['replyToken']
      @line_service.reply_message(reply_token, reply_message)
    end

    Rails.logger.info "Finished processing message event for user #{line_user_id}"
  rescue StandardError => e
    Rails.logger.error "Error in handle_message: #{e.class.name} - #{e.message}"
    raise
  end

  # FOR CLIENT
  def handle_message2(event)
    # Extract necessary data from the event
    message_data = event['message']
    source_data = event['source']

    # Extract individual fields
    message_id = message_data['id']
    message_text = message_data['text']
    line_user_id = source_data['userId']
    reply_token = event['replyToken']
    timestamp = event['timestamp']
    client_id = Client.find_by(lineid: line_user_id)&.id

    client_profile = @line_service.get_profile(line_user_id)

    # Log event data (optional)
    log_event(event)

    translate = Google::Cloud::Translate::V2.new(
      key: ENV.fetch("GOOGLE_TRANSLATE_API_KEY")
    )

    translation = translate.translate(message_text, to: "en")
    translated_message = translation.text

    # Create and store the message in the database
    message = Message.create!(
      message_id:,
      contents: translated_message,
      sender: client_profile[:display_name],
      reply_token:,
      timestamp: Time.at(timestamp / 1000), # Convert timestamp to datetime
      client_id:,
      user_id: User.last.id, # Assuming this is from the client, so user_id can be nil 'TODO: MAKE IT COME FROM LINE WHEN THE USER SELECTS THE ID FROM THE RICH MENU BEFORE RELEASE!'
      uuid: SecureRandom.uuid
    )

    # Broadcast the message to the appropriate ActionCable channel
    ActionCable.server.broadcast(
      "chat_channel",
      {
        message_id: message.uuid,
        is_teacher: false,
        sender: message.sender,
        message: translated_message
      }
    )

    # Respond with a status if needed
    render json: { status: "Message received", message_id: message.uuid }, status: :ok
  end

  def handle_postback(event)
    log_event(event)
    user_id = event['source']['userId']
    data = event['postback']['data']

    Rails.logger.debug "Postback data: #{data}"

    teacher = @teachers.find { |t| t[:id] == teacher_id }
    message = {
      type: 'text',
      text: "You're now chatting with Teacher #{teacher[:name]}. Your messages will be sent to this teacher.\n\nHow can
      I help you today?\nPlease select your preferred number below.\n1. lesson reservation, change, or cancellation\n2.
      confirm your reserved lesson\n3. other"
    }

    begin
      response = @line_service.reply_message(event['replyToken'], message)
      Rails.logger.info "Postback reply sent successfully for user #{user_id} with response #{response}"
    rescue StandardError => e
      Rails.logger.error "Error sending postback reply: #{e.message}"
    end
  end

  def handle_follow(event)
    # log_event(event)
    user_id = event['source']['userId']

    user_profile = @line_service.get_profile(user_id)

    display_name = user_profile[:display_name]

    new_client = Client.create!(lineid: user_id, phone_number: "", name: display_name)

    new_client.save!

    begin
      message = {
        type: 'text',
        # text: "Welcome! You've been assigned to all our teachers. Use the menu at the bottom to select a teacher
        # and start chatting!"
        text: "Welcome! You can start using LinguaLink by typing '#' for a list of menu options."
      }

      response = @line_service.reply_message(event['replyToken'], message)
      Rails.logger.info "Welcome message sent successfully for new follower #{user_id} with response #{response}"
    rescue StandardError => e
      Rails.logger.error "Error handling follow event: #{e.message}"
    end
  end

  def create_rich_menu(event)
    log_event(event, "CREATE_RICH_MENU")
    user_id = event['source']['userId']

    begin
      response = @line_service.create_rich_menu(rich_menu)
      Rails.logger.info "Rich menu created successfully for user #{user_id} with response #{response}"
    rescue StandardError => e
      Rails.logger.error "Error creating rich menu: #{e.message}"
    end
  end

  private

  def log_event(event, type = nil)
    @logged ||= {}
    return if @logged[event]

    user_id = event['source']['userId']
    type ||= event.type.upcase

    Rails.logger.info "Handling [#{type}] event for user [#{user_id}]"
    @logged[event] = true
  end

  def set_client
    @line_service = LineService.new
  end
end
