module Pages.Home_ exposing (Model, Msg, page)

import Html exposing (Html)
import Html.Attributes exposing (autofocus, href, target)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode exposing (field, string)
import Page exposing (Page)
import Platform.Cmd as Cmd
import Url exposing (percentEncode)
import View exposing (View)


sites : List { label : String, url : String }
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
    , steamId : String
    }


init : ( Model, Cmd Msg )
init =
    ( { input = "", steamId = "" }
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
            ( model, Http.get { url = "/player/" ++ percentEncode model.input, expect = Http.expectJson GotResult (field "steam_id" string) } )

        GotResult (Ok content) ->
            ( { model | steamId = content }, Cmd.none )

        GotResult (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Finder"
    , body =
        [ Html.form [ onSubmit Submit ]
            [ Html.input [ autofocus True, onInput <| UpdateInput ] []
            ]
        , if model.steamId /= "" then
            links model

          else
            Html.text ""
        ]
    }


links : Model -> Html Msg
links { steamId } =
    Html.ul [] <| List.map (link steamId) sites


link : String -> { label : String, url : String } -> Html Msg
link steamId { label, url } =
    Html.li [] [ Html.a [ target "blank", href <| url ++ steamId ] [ Html.text label ] ]
