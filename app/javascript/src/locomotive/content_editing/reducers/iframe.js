import update from '../utils/immutable_update';

const refreshSection = (state, action) => {
  return update(state, {
    refreshAction:  { $set: 'refreshSection' },
    sectionType:    { $set: action.sectionType }
  });
}

function iframe(state = {}, action) {
  switch(action.type) {
    case 'IFRAME::LOADED':
      return { loaded: true, window: action.window };

    case 'SECTION::PREVIEW':
      return update(state, {
        refreshAction:      { $set: 'previewSection' },
        section:            { $set: action.newSection },
        previousSectionId:  {
          $set: state.section ? state.section.id : null
        }
      });

    case 'SECTION::ADD':
      return update(state, {
        refreshAction:      { $set: null },
        section:            { $set: null }
      });

    case 'SECTION::CANCEL_PREVIEW':
      if (!state.section) return state;
      return update(state, {
        refreshAction:      { $set: 'removeSection' },
        sectionId:          { $set: state.section.id },
        previousSectionId:  { $set: null }
      });

    case 'SECTION::MOVE':
      return update(state, {
        refreshAction:      { $set: 'moveSection' },
        sectionId:          { $set: action.sectionId },
        targetSectionId:    { $set: action.targetSectionId },
        direction:          { $set: action.newIndex > action.oldIndex ? 'after' : 'before' }
      });

    case 'SECTION::REMOVE':
      return update(state, {
        refreshAction:      { $set: 'removeSection' },
        sectionId:          { $set: action.sectionId }
      });

    case 'SECTION::UPDATE_INPUT':
    case 'SECTION::BLOCK::UPDATE_INPUT':
    case 'STATIC_SECTION::BLOCK::UPDATE_INPUT':
    case 'STATIC_SECTION::UPDATE_INPUT':
      if (action.fieldType === 'text')
        return update(state, {
          refreshAction:    { $set: 'updateInput' },
          sectionType:      { $set: action.sectionType },
          sectionId:        { $set: action.sectionId },
          blockId:          { $set: action.blockId },
          fieldId:          { $set: action.id },
          fieldValue:       { $set: action.newValue }
        });
      else
        return refreshSection(state, action);

    case 'SECTION::BLOCK::ADD':
    case 'SECTION::BLOCK::REMOVE':
    case 'SECTION::BLOCK::MOVE':
    case 'STATIC_SECTION::BLOCK::ADD':
    case 'STATIC_SECTION::BLOCK::REMOVE':
    case 'STATIC_SECTION::BLOCK::MOVE':
      return refreshSection(state, action);

    case 'IFRAME::DONE':
      return update(state, {
        refreshAction:      { $set: null },
        refreshInput:       { $set: null }
      })

   default:
    return state;
  }
}

export default iframe;
