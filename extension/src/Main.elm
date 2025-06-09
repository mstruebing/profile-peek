port module Main exposing (main)

import API exposing (Response, baseUrl, playerUrl, responseDecoder, responseEncoder)
import Browser
import Components exposing (icon, link, logoButton, sideBar, stringToIconType)
import Html exposing (Html)
import Html.Attributes
import Http exposing (Error(..))
import Json.Decode exposing (decodeString)
import Json.Encode
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)


port requestLocalStorageItem : String -> Cmd msg


port receiveLocalStorageItem : (String -> msg) -> Sub msg


port setLocalStorageItem : ( String, Json.Encode.Value ) -> Cmd msg


type alias Flags =
    { url : String }



-- https://steamcommunity.com/id/insi--/inventory/
-- -> https://steamcommunity.com/id/insi--


normalizeUrl : String -> String
normalizeUrl url =
    case String.split "/" url of
        [] ->
            url

        parts ->
            String.join "/" (List.take 5 parts)



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
    ( { url = normalizeUrl flags.url
      , response = RemoteData.NotAsked
      }
    , Cmd.batch
        [ Http.get
            { url = playerUrl ++ "/" ++ percentEncode flags.url
            , expect = Http.expectJson GotResult responseDecoder
            }
        , requestLocalStorageItem flags.url
        ]
    )



-- UPDATE


type Msg
    = GotResult (Result Http.Error Response)
    | GotLocalStorageResult String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, setLocalStorageItem ( model.url, responseEncoder response ) )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Cmd.none )

        GotLocalStorageResult value ->
            case decodeString responseDecoder value of
                Ok response ->
                    ( { model | response = RemoteData.Success response }, Cmd.none )

                Err _ ->
                    ( { model | response = RemoteData.Failure (BadBody value) }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveLocalStorageItem GotLocalStorageResult



-- VIEW


view : Model -> Html Msg
view model =
    case model.response of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.text ""

        RemoteData.Success response ->
            sideBar <| link (baseUrl ++ "/" ++ model.url) logoButton :: responseToLinks response

        RemoteData.Failure _ ->
            Html.text ""


responseToLinks : Response -> List (Html msg)
responseToLinks response =
    response.sites
        |> List.filter (\s -> s.title /= "Steam")
        |> List.map (siteToLink response.faceitData)


siteToLink : Maybe API.FaceitData -> API.Site -> Html msg
siteToLink faceitData site =
    if site.title == "Faceit" then
        case faceitData of
            Just data ->
                link site.url
                    (Html.img
                        [ Html.Attributes.src (API.assetUrl ++ "/icons/faceit/level" ++ String.fromInt data.level ++ ".svg")
                        , Html.Attributes.alt "Faceit Level"
                        , Html.Attributes.style "width" "30px"
                        , Html.Attributes.style "height" "30px"
                        ]
                        []
                    )

            Nothing ->
                link site.url (icon (stringToIconType site.title) 20 20)

    else
        link site.url (icon (stringToIconType site.title) 20 20)
