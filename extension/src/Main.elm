module Main exposing (main)

import Browser
import Html exposing (Html, text)
import Html.Attributes exposing (class, href, style, target)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, field)
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)


type alias Flags =
    { url : String }


type alias Response =
    { steam_id : String
    , sites : List Site
    }


type alias Site =
    { title : String, url : String }



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }



-- INIT


type alias Model =
    { url : String
    , response : RemoteData Http.Error Response
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { url = flags.url, response = RemoteData.NotAsked }
    , Http.get { url = "https://finder.maex.me/player/" ++ percentEncode flags.url, expect = Http.expectJson GotResult responseDecoder }
    )



-- UPDATE


type Msg
    = GotResult (Result Http.Error Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, Cmd.none )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    column
        [ style "position" "fixed"
        , style "top" "50%"
        , style "left" "0"
        , style "transform" "translate(50%, -50%)"
        ]
        [ case model.response of
            RemoteData.NotAsked ->
                Html.text ""

            RemoteData.Loading ->
                Html.text ""

            RemoteData.Success response ->
                Html.div [] [ links <| List.filter (\s -> s.title /= "Steam") response.sites ]

            RemoteData.Failure _ ->
                Html.text ""
        ]


links : List Site -> Html Msg
links sites =
    row [] <| List.map link sites


link : Site -> Html Msg
link { title, url } =
    column [] [ Html.a [ target "blank", href url ] [ Html.text title ] ]


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


responseDecoder : Decoder Response
responseDecoder =
    Json.Decode.map2 Response
        (field "steam_id" Json.Decode.string)
        sitesDecoder


sitesDecoder : Decoder (List Site)
sitesDecoder =
    field "sites" (Json.Decode.list siteDecoder)


siteDecoder : Decoder Site
siteDecoder =
    Json.Decode.map2 Site
        (field "title" Json.Decode.string)
        (field "url" Json.Decode.string)
