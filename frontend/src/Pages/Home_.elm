module Pages.Home_ exposing (Model, Msg, page)

import Html exposing (Html)
import Html.Attributes exposing (autofocus, class, disabled, href, placeholder, target)
import Html.Events exposing (onInput, onSubmit)
import Http exposing (Error(..))
import Json.Decode exposing (field, string)
import Page exposing (Page)
import Platform.Cmd as Cmd
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)
import View exposing (View)


type alias Site =
    { label : String, url : String }


sites : List Site
sites =
    [ { label = "steam profile", url = "https://steamcommunity.com/profiles/" }
    , { label = "leetify", url = "https://leetify.com/app/profile/" }
    , { label = "faceitfinder", url = "https://faceitfinder.com/profile/" }
    , { label = "csstats", url = "https://csstats.gg/player/" }
    , { label = "csbackpack", url = "https://www.csbackpack.net/inventory/" }
    ]


page : Page Model Msg
page =
    Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { input : String
    , steamId : RemoteData Http.Error String
    }


init : ( Model, Cmd Msg )
init =
    ( { input = "", steamId = RemoteData.NotAsked }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | UpdateInput String
    | Submit
    | GotResult (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        UpdateInput input ->
            ( { model | input = input }, Cmd.none )

        Submit ->
            ( { model | steamId = RemoteData.Loading }, Http.get { url = "/player/" ++ percentEncode model.input, expect = Http.expectJson GotResult (field "steam_id" string) } )

        GotResult (Ok content) ->
            ( { model | steamId = RemoteData.Success content }, Cmd.none )

        GotResult (Err error) ->
            ( { model | steamId = RemoteData.Failure error }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Finder"
    , body =
        [ column [ class "gap" ]
            [ Html.form [ onSubmit Submit ]
                [ Html.input
                    [ disabled <| model.steamId == RemoteData.Loading
                    , placeholder "steam link"
                    , autofocus True
                    , onInput <| UpdateInput
                    ]
                    []
                , row [] [ Html.button [ disabled <| model.steamId == RemoteData.Loading ] [ Html.text "search" ] ]
                ]
            , case model.steamId of
                RemoteData.NotAsked ->
                    Html.text ""

                RemoteData.Loading ->
                    Html.div [ class "loading" ] [ Html.text "loading..." ]

                RemoteData.Success steamId ->
                    Html.div [] [ links steamId ]

                RemoteData.Failure error ->
                    column [ class "error" ]
                        [ Html.div [] [ Html.text <| errorToString error ]
                        , Html.div [] [ Html.text "Try again" ]
                        ]
            ]
        ]
    }


links : String -> Html Msg
links steamId =
    row [ class "link__row" ] <| List.map (link steamId) sites


link : String -> { label : String, url : String } -> Html Msg
link steamId { label, url } =
    column [ class "link" ] [ Html.a [ target "blank", href <| url ++ steamId ] [ Html.text label ] ]


row : List (Html.Attribute msg) -> List (Html msg) -> Html msg
row attrs children =
    let
        attributes =
            class "row" :: attrs
    in
    Html.div attributes children


column : List (Html.Attribute msg) -> List (Html msg) -> Html msg
column attrs children =
    let
        attributes =
            class "column" :: attrs
    in
    Html.div attributes children


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
