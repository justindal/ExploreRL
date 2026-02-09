//
//  EnvLoadState.swift
//  ExploreRL
//

import Gymnazo

enum EnvLoadState {
    case idle
    case loading
    case loaded(any Env)
    case error(Error)
}
