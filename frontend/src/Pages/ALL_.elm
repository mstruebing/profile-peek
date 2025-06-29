module Pages.ALL_ exposing (Model, Msg, page)

import API exposing (Response, Site, responseDecoder)
import Components exposing (IconType(..), footer)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (autofocus, disabled, placeholder, style, value)
import Html.Events exposing (onInput, onSubmit)
import Http exposing (Error(..))
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Route.Path as Path
import Shared
import Time exposing (millisToPosix, toDay, toMonth, toYear, utc)
import Url exposing (percentEncode)
import View exposing (View)


page : Shared.Model -> Route { all_ : List String } -> Page Model Msg
page _ route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { response : RemoteData Http.Error Response
    , input : String
    }


init : Route { all_ : List String } -> () -> ( Model, Effect Msg )
init route () =
    ( { response = RemoteData.Loading, input = routeToPlayerUrl route }
    , Effect.sendCmd <|
        getPlayerEffect (routeToPlayerUrl route)
    )


getPlayerEffect : String -> Cmd Msg
getPlayerEffect route =
    Http.get
        { url = API.playerUrl ++ "/" ++ percentEncode route
        , expect = Http.expectJson GotResult responseDecoder
        }


routeToPlayerUrl : Route { all_ : List String } -> String
routeToPlayerUrl route =
    String.slice 1 (String.length route.url.path) route.url.path



-- UPDATE


type Msg
    = NoOp
    | UpdateInput String
    | Submit
    | GotResult (Result Http.Error API.Response)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )

        UpdateInput input ->
            ( { model | input = input }, Effect.none )

        Submit ->
            ( { model | response = RemoteData.Loading }
            , Effect.batch
                [ Effect.sendCmd <| getPlayerEffect model.input
                , Effect.pushRoutePath <| Path.ALL_ { all_ = [ model.input ] }
                ]
            )

        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, Effect.none )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Profile-Peek - Easy Access to Player Profiles Across Platforms"
    , body =
        [ header model
        , Html.div
            [ Html.Attributes.id "wrapper"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "justify-content" "space-between"
            , style "gap" "50px"
            , style "margin-top" "150px"
            , style "min-height" "70vh"
            ]
            [ searchResults model ]
        , footer
        ]
    }


header : Model -> Html Msg
header model =
    Html.header
        [ style "background-color" "rgb(34, 32, 32)"
        , style "width" "100%"
        , style "position" "fixed"
        , style "top" "10px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "space-between"
        , style "padding" "20px"
        ]
        [ Html.a [ Html.Attributes.href "/" ] [ Components.logo ]
        , searchBox model
        , buyMeACoffee
        ]


searchBox : Model -> Html Msg
searchBox model =
    Html.div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "flex-grow" "1"
        ]
        [ Html.form
            [ onSubmit Submit
            , style "width" "100%"
            ]
            [ Html.div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "flex-direction" "row"
                , style "width" "90%"
                , style "margin" "0 auto"
                , style "margin-left" "112px"
                ]
                [ Html.input
                    [ placeholder "Enter the Steam Profile URL"
                    , Html.Attributes.name "steam profile url"
                    , autofocus True
                    , onInput UpdateInput
                    , value model.input
                    , style "max-width" "500px"
                    , style "width" "100%"
                    , style "height" "40px"
                    , style "line-height" "35px"
                    , style "font-size" "16px"
                    , style "border-radius" "22px"
                    , style "padding" "5px 12px"
                    , style "background-color" "white"
                    ]
                    []
                , Html.div [ style "transform" "translateX(-112px)" ]
                    [ Html.button
                        [ disabled <|
                            String.isEmpty model.input
                                || (model.response == RemoteData.Loading)
                        , style "background-color" "#123"
                        , style "cursor" "pointer"
                        , style "border" "none"
                        , style "color" "white"
                        , style "border-radius" "22px"
                        , style "padding" "0 0 0 6px"
                        , Html.Attributes.id "submit-button"
                        ]
                        [ Html.div
                            [ style "display" "flex"
                            , style "align-items" "center"
                            , style "justify-content" "center"
                            , style "gap" "10px"
                            ]
                            [ Html.text "Search"
                            , Components.icon (Just Components.ProfilePeek) 54 54
                            ]
                        ]
                    ]
                ]
            ]
        ]


searchResults : Model -> Html Msg
searchResults model =
    case model.response of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.text ""

        RemoteData.Success response ->
            Html.div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "gap" "20px"
                ]
                [ faceitProfile response.faceitData
                , cs2Hours response.cs2Hours
                , faceitStats response.faceitData
                , accountCreation response.accountCreated response.faceitData
                , Html.div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "5px"
                    , style "align-items" "center"
                    , style "justify-content" "center"
                    ]
                    [ Html.p [ style "text-decoration" "underline" ] [ Html.text "Bans:" ]
                    , vacBanInfo response.vacBanInfo
                    , faceitBanInfo
                        (case response.faceitData of
                            Just data ->
                                data.bans

                            Nothing ->
                                []
                        )
                    ]
                , Html.hr [ style "width" "400px", style "border" "1px solid #ccc" ] []
                , linkList response.sites
                ]

        RemoteData.Failure error ->
            Html.text (errorToString error)


linkList : List Site -> Html msg
linkList sites =
    Html.div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "gap" "20px"
        ]
        (sites
            |> List.map
                (\site ->
                    Components.link site.url (Components.icon (Components.stringToIconType site.title) 40 40)
                )
        )


vacBanInfo : Maybe API.VacBanInfo -> Html msg
vacBanInfo maybeVacBanInfo =
    case maybeVacBanInfo of
        Nothing ->
            Html.text ""

        Just info ->
            Html.div
                [ style "display" "flex", style "flex-direction" "column", style "align-items" "center", style "justify-content" "center", style "gap" "5px" ]
                [ Html.div
                    [ style "display" "flex", style "align-items" "center", style "justify-content" "center", style "gap" "10px" ]
                    [ Html.p []
                        [ Html.text "Vac: " ]
                    , if not info.isBanned then
                        Components.icon (Just Checkmark) 20 20

                      else
                        Components.icon (Just Error) 20 20
                    ]
                , if info.isBanned then
                    Html.p []
                        [ Html.text <|
                            String.fromInt info.banCount
                                ++ " ban(s)"
                                ++ (case info.daysSinceLastBan of
                                        Just days ->
                                            " (" ++ String.fromInt days ++ " days since last ban)"

                                        Nothing ->
                                            ""
                                   )
                        ]

                  else
                    Html.text ""
                ]


faceitBanInfo : List API.FaceitBan -> Html Msg
faceitBanInfo bans =
    if List.isEmpty bans then
        Html.div
            [ style "display" "flex", style "flex-direction" "column", style "align-items" "center", style "justify-content" "center", style "gap" "5px" ]
            [ Html.div
                [ style "display" "flex", style "align-items" "center", style "justify-content" "center", style "gap" "10px" ]
                [ Html.p [] [ Html.text "Faceit: " ]
                , Components.icon (Just Components.Checkmark) 20 20
                ]
            ]

    else
        Html.div
            [ style "display" "flex", style "flex-direction" "column", style "align-items" "center", style "justify-content" "center", style "gap" "5px" ]
            [ Html.div
                [ style "display" "flex", style "align-items" "center", style "justify-content" "center", style "gap" "10px" ]
                [ Html.p []
                    [ Html.text "Faceit: " ]
                , Components.icon (Just Components.Error) 20 20
                ]
            , Html.div [] (List.map (\x -> Html.p [] [ Html.text <| x.reason ++ ": " ++ getAccountCreationDate x.startsAt ]) bans)
            ]


cs2Hours : Maybe Int -> Html msg
cs2Hours maybeHours =
    case maybeHours of
        Nothing ->
            Html.p [] [ Html.text "CS2 Hours: private" ]

        Just hours ->
            Html.p []
                [ Html.text
                    ("CS2 Hours: "
                        ++ (if hours == 0 then
                                "private"

                            else
                                String.fromInt hours
                           )
                    )
                ]


faceitProfile : Maybe API.FaceitData -> Html msg
faceitProfile faceitData =
    case faceitData of
        Nothing ->
            Html.p [] [ Html.text "No Faceit Data Found 🤔" ]

        Just data ->
            Html.div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "gap" "12px"
                ]
                [ Html.img
                    [ Html.Attributes.src
                        (if String.isEmpty data.avatar then
                            API.assetUrl ++ "/icons/faceit/default-avatar.svg"

                         else
                            data.avatar
                        )
                    , Html.Attributes.alt "Faceit Avatar"
                    , style "width" "100px"
                    , style "height" "100px"
                    ]
                    []
                , Html.div
                    [ style "display" "flex", style "gap" "8px", style "align-items" "center" ]
                    [ Html.img [ Html.Attributes.alt <| "Country: " ++ String.toUpper data.country, Html.Attributes.src ("https://flagsapi.com/" ++ String.toUpper data.country ++ "/flat/24.png") ] []
                    , Html.p [] [ Html.text data.nickname ]
                    , Html.img
                        [ Html.Attributes.src (API.assetUrl ++ "/icons/faceit/level" ++ String.fromInt data.level ++ ".svg")
                        , Html.Attributes.alt "Faceit Level"
                        , style "width" "30px"
                        , style "height" "30px"
                        ]
                        []
                    , Html.p [] [ Html.text <| String.fromInt data.elo ]
                    ]
                ]


faceitStats : Maybe API.FaceitData -> Html msg
faceitStats faceitData =
    case faceitData of
        Nothing ->
            Html.text ""

        Just data ->
            Html.div [ style "display" "flex", style "flex-direction" "column", style "align-items" "center", style "justify-content" "center", style "gap" "5px" ]
                [ Html.p [ style "text-align" "center", style "text-decoration" "underline" ] [ Html.text "Last 20 matches avg:" ]
                , Html.div
                    [ style "display" "flex"
                    , style "align-items" "center"
                    , style "justify-content" "center"
                    , style "gap" "10px"
                    ]
                    [ truncate data.adr |> String.fromInt |> property "ADR"
                    , formatFloat data.kd_ratio |> property "K/D"
                    , formatFloat data.kr_ratio |> property "K/R"
                    , data.win_rate |> String.fromInt |> property "Win%"
                    , truncate data.headshot_percentage |> String.fromInt |> property "HS%"
                    ]
                ]


accountCreation : Maybe Int -> Maybe API.FaceitData -> Html msg
accountCreation maybeSteamTimestamp maybeFaceitData =
    Html.div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "gap" "5px"
        ]
        [ Html.p [ style "text-decoration" "underline" ] [ Html.text "Account Creation:" ]
        , Html.p []
            [ Html.text <|
                "Steam: "
                    ++ (case maybeSteamTimestamp of
                            Just timestamp ->
                                getAccountCreationDate timestamp

                            Nothing ->
                                "Unknown"
                       )
            ]
        , Html.p []
            [ Html.text <|
                "Faceit: "
                    ++ (case maybeFaceitData of
                            Just data ->
                                getAccountCreationDate data.account_created

                            Nothing ->
                                "Unknown"
                       )
            ]
        ]


getAccountCreationDate : Int -> String
getAccountCreationDate timestamp =
    let
        posixTime =
            timestamp
                * 1000
                |> millisToPosix

        year =
            toYear utc posixTime

        month =
            toMonth utc posixTime

        day =
            toDay utc posixTime
    in
    String.fromInt day ++ " " ++ monthToString month ++ " " ++ String.fromInt year


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


formatFloat : Float -> String
formatFloat value =
    String.fromFloat <| (value * 100 |> round |> toFloat) / 100


property : String -> String -> Html msg
property name value =
    Html.p
        []
        [ Html.text <| name ++ ": " ++ value
        ]


errorToString : Http.Error -> String
errorToString err =
    case err of
        Timeout ->
            "Timeout exceeded"

        NetworkError ->
            "Network error"

        BadStatus resp ->
            String.fromInt resp

        BadBody text ->
            "Unexpected response from api: " ++ text

        BadUrl url ->
            "Malformed url: " ++ url


buyMeACoffee : Html Msg
buyMeACoffee =
    Html.a
        [ Html.Attributes.href "https://www.buymeacoffee.com/mstruebing"
        , Html.Attributes.target "_blank"
        , Html.Attributes.style "margin-right" "40px"
        ]
        [ Html.img
            [ Html.Attributes.src "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
            , Html.Attributes.alt "Buy Me A Coffee"
            , Html.Attributes.height 40
            , Html.Attributes.width 142
            ]
            []
        ]
